# coding: ascii-8bit
# Copyright (C) 2006-2011 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/error"
require "mailparser/rfc2045"
require "mailparser/rfc2047"
require "mailparser/rfc2183"
require "mailparser/rfc2231"
require "mailparser/rfc2822"
require "mailparser/loose"
require "mailparser/conv_charset"
require "mmapscanner"

require "stringio"
require "tempfile"

# メールをパースする。
#
#   m = MailParser.new
#   m.parse(src)
#   m.header => #<MailParser::Header>
#   m.body => パースされた本文文字列
#   m.part => [#<Mailparser>, ...]
#
module MailParser
  include RFC2045, RFC2183, RFC2822

  HEADER_PARSER = {
    "date"                      => RFC2822,
    "from"                      => RFC2822,
    "sender"                    => RFC2822,
    "reply-to"                  => RFC2822,
    "to"                        => RFC2822,
    "cc"                        => RFC2822,
    "bcc"                       => RFC2822,
    "message-id"                => RFC2822,
    "in-reply-to"               => RFC2822,
    "references"                => RFC2822,
#    "subject"                   => RFC2822,
#    "comments"                  => RFC2822,
    "keywords"                  => RFC2822,
    "resent-date"               => RFC2822,
    "resent-from"               => RFC2822,
    "resent-sender"             => RFC2822,
    "resent-to"                 => RFC2822,
    "resent-cc"                 => RFC2822,
    "resent-bcc"                => RFC2822,
    "resent-message-id"         => RFC2822,
    "return-path"               => RFC2822,
    "received"                  => RFC2822,
    "content-type"              => RFC2045,
#    "content-description"       => RFC2045,
    "content-transfer-encoding" => RFC2045,
    "content-id"                => RFC2045,
    "mime-version"              => RFC2045,
    "content-disposition"       => RFC2183,
  }

  # 単一のヘッダ
  class HeaderItem
    # name:: ヘッダ名(String)
    # raw:: ヘッダ値(String)
    # opt:: オプション(Hash)
    #  :decode_mime_header::   MIMEヘッダをデコードする
    #  :output_charset::       デコード出力文字コード(デフォルト: UTF-8)
    #  :strict::               RFC違反時に ParseError 例外を発生する
    def initialize(name, raw, opt={})
      @name = name
      @raw = raw
      @parsed = nil
      @opt = opt
    end

    attr_reader :raw

    # パースした結果オブジェクトを返す
    def parse()
      return @parsed if @parsed
      if HEADER_PARSER.key? @name then
        begin
          @parsed = HEADER_PARSER[@name].parse(@name, @raw, @opt)
        rescue ParseError
          raise if @opt[:strict]
          @parsed = Loose.parse(@name, @raw, @opt)
        end
      else
        r = @raw.chomp.gsub(/\s+/, " ")
        if @opt[:decode_mime_header] then
          @parsed = RFC2047.decode(r, @opt)
        else
          @parsed = r
        end
      end
      class <<@parsed
        attr_accessor :raw
      end
      @parsed.raw = @raw

      # Content-Type, Content-Disposition parameter for RFC2231
      if ["content-type", "content-disposition"].include? @name
        new = RFC2231.parse_param @parsed.params, @opt
        @parsed.params.replace new
      end

      return @parsed
    end
  end

  # 同じ名前を持つヘッダの集まり
  class Header
    def initialize(opt={})
      @hash = {}
      @parsed = {}
      @raw = {}
      @opt = opt
    end

    # name ヘッダに body を追加する
    # name:: ヘッダ名(String)
    # body:: ヘッダ値(String)
    def add(name, body)
      name = name.downcase
      @hash[name] = [] unless @hash.key? name
      @hash[name] << HeaderItem.new(name, body, @opt)
    end

    # パースした結果オブジェクトの配列を返す
    # name:: ヘッダ名(String)
    def [](name)
      return nil unless @hash.key? name
      return @parsed[name] if @parsed.key? name
      @parsed[name] = @hash[name].map{|h| h.parse}.compact
      return @parsed[name]
    end

    # 生ヘッダ値文字列の配列を返す
    # name:: ヘッダ名(String)
    def raw(name)
      return nil unless @hash.key? name
      return @raw[name] if @raw.key? name
      @raw[name] = @hash[name].map{|h| h.raw}
      return @raw[name]
    end

    # ヘッダ名の配列を返す
    def keys()
      return @hash.keys
    end

    # ヘッダが存在するか？
    def key?(name)
      return @hash.key?(name)
    end

    # 各ヘッダについてブロックを繰り返す
    # ブロック引数は、[ヘッダ名, パース結果オブジェクト,...]]
    def each()
      @hash.each do |k, v|
        yield k, self[k]
      end
    end
  end

  # メール全体またはひとつのパートを表すクラス
  class Message
    # src からヘッダ部を読み込み Header オブジェクトに保持する
    # src:: String / File / MmapScanner / read メソッドを持つオブジェクト
    # opt:: オプション(Hash)
    #  :extract_message_type:: message/* type を展開する
    #  :decode_mime_header::   MIMEヘッダをデコードする
    #  :decode_mime_filename:: ファイル名を MIME デコードする
    #  :output_charset::       デコード出力文字コード(デフォルト: 変換しない)
    #  :strict::               RFC違反時に ParseError 例外を発生する
    #  :charset_converter::    文字コード変換用 Proc または Method
    def initialize(src, opt={})
      if src.is_a? String
        @src = MmapScanner.new src
      elsif src.is_a? File and src.stat.ftype == 'file'
        @src = MmapScanner.new src
      elsif src.is_a? StringIO
        @src = MmapScanner.new src.string
      elsif src.is_a? MmapScanner
        @src = src
      else
        tmpf = Tempfile.new 'mailparser'
        buf = ''
        while src.read(4096, buf)
          tmpf.write buf
        end
        tmpf.close
        @src = File.open(tmpf.path){|f| MmapScanner.new f}
        File.unlink tmpf.path
      end

      @opt = opt
      @from = @to = @cc = @subject = nil
      @type = @subtype = @charset = @content_transfer_encoding = @filename = nil
      @rawheader = nil
      @rawbody = nil
      @part = []
      opt[:charset_converter] ||= ConvCharset.method(:conv_charset)

      read_header
      read_part
    end

    attr_reader :header, :part

    # charset 変換後の本文を返す
    def body
      body = body_preconv
      if type == 'text' and charset and @opt[:output_charset]
        begin
          body = @opt[:charset_converter].call(charset, @opt[:output_charset], body)
        rescue
          # ignore
        end
      end
      body
    end

    # charset 変換前の本文を返す
    def body_preconv
      return '' if type == 'multipart' or type == 'message'
      body = @rawbody.to_s
      ret = case content_transfer_encoding
            when "quoted-printable" then RFC2045.qp_decode(body)
            when "base64" then RFC2045.b64_decode(body)
            when "uuencode", "x-uuencode", "x-uue" then decode_uuencode(body)
            else body
            end
      if type == 'text' and charset
        ret.force_encoding(charset) rescue nil
      end
      ret
    end

    # Content-Type が message の時 Message を返す。そうでなければ nil を返す。
    def message
      unless @opt[:extract_message_type] and type == "message"
        return nil
      end
      if ['7bit', '8bit'].include? content_transfer_encoding
        @rawbody.pos = 0
        return Message.new(@rawbody, @opt)
      end
      return Message.new(body_preconv, @opt)
    end

    # From ヘッダがあれば Mailbox を返す。
    # なければ nil
    def from()
      return @from if @from
      if @header.key? "from" then
        @from = @header["from"][0][0]
      else
        @from = nil
      end
      return @from
    end

    # To ヘッダがあれば Mailbox の配列を返す
    # なければ空配列
    def to()
      return @to if @to
      if @header.key? "to" then
        @to = @header["to"].flatten
      else
        @to = []
      end
      return @to
    end

    # Cc ヘッダがあれば Mailbox の配列を返す
    # なければ空配列
    def cc()
      return @cc if @cc
      if @header.key? "cc" then
        @cc = @header["cc"].flatten
      else
        @cc = []
      end
      return @cc
    end

    # Subject ヘッダがあれば文字列を返す
    # なければ空文字
    def subject()
      return @subject if @subject
      if @header.key? "subject" then
        @subject = @header["subject"].join(" ")
      else
        @subject = ""
      end
      return @subject
    end

    # Content-Type の type を返す。
    # Content-Type がない場合は "text"
    def type()
      return @type if @type
      if @header.key? "content-type" then
        @type = @header["content-type"][0].type
      else
        @type = "text"
      end
      return @type
    end

    # Content-Type の subtype を返す。
    # Content-Type がない場合は "plain"
    def subtype()
      return @subtype if @subtype
      if @header.key? "content-type" then
        @subtype = @header["content-type"][0].subtype
      else
        @subtype = "plain"
      end
      return @subtype
    end

    # Content-Type の charset 属性の値(小文字)を返す。
    # charset 属性がない場合は nil
    def charset()
      return @charset if @charset
      if @header.key? "content-type" then
        c = @header["content-type"][0].params["charset"]
        @charset = c && c.downcase
      else
        @charset = nil
      end
      return @charset
    end

    # マルチパートメッセージかどうかを返す
    def multipart?()
      return type == "multipart"
    end

    # Content-Transfer-Encoding の mechanism を返す
    # Content-Transfer-Encoding がない場合は "7bit"
    def content_transfer_encoding()
      return @content_transfer_encoding if @content_transfer_encoding
      if @header.key? "content-transfer-encoding" then
        @content_transfer_encoding = @header["content-transfer-encoding"][0].mechanism
      else
        @content_transfer_encoding = "7bit"
      end
      return @content_transfer_encoding
    end

    # ファイル名を返す。
    # Content-Disposition の filename パラメータ
    # または Content-Type の name パラメータ。
    # デフォルトは nil。
    def filename()
      return @filename if @filename
      if @header.key? "content-disposition" and @header["content-disposition"][0].params.key? "filename" then
        @filename = @header["content-disposition"][0].params["filename"]
      elsif @header.key? "content-type" and @header["content-type"][0].params.key? "name" then
        @filename = @header["content-type"][0].params["name"]
      end
      @filename = RFC2047.decode(@filename, @opt) if @opt[:decode_mime_filename] and @filename
      return @filename
    end

    # 生メッセージを返す
    def raw
      return @src.to_s
    end

    # 生ヘッダを返す
    def rawheader
      @rawheader.to_s
    end

    private

    # ヘッダ部をパースする
    def read_header()
      @rawheader = @src.scan_until(/^(?=\r?\n)|\z/)
      @header = Header.new(@opt)
      until @rawheader.eos?
        if @rawheader.skip(/(.*?)[ \t]*:[ \t]*(.*(\r?\n[ \t].*)*(\r?\n)?)/)
          name = @rawheader.matched(1).to_s
          body = @rawheader.matched(2).to_s
          @header.add(name, body)
        else
          @rawheader.skip(/.*\n/) or break
        end
      end
      @src.scan(/\r?\n/)        # 空行スキップ
      @rawbody = @src.rest
    end

    # 各パートの Message オブジェクトの配列を作成
    def read_part()
      return if type != "multipart" or @src.eos?
      b = @header["content-type"][0].params["boundary"]
      re = /(?:\A|\r?\n)--#{Regexp.escape b}(?:|(--))(?:\r?\n|\z)/
      @src.scan_until(re) or return  # skip preamble
      until @src.eos?
        unless p = @src.scan_until(re)
          @part.push Message.new(@src.rest, @opt)
          break
        end
        @part.push Message.new(p.peek(p.size-@src.matched.length), @opt)
        break if @src.matched(1)
      end
    end

    # uuencode のデコード
    def decode_uuencode(str)
      ret = ""
      str.each_line do |line|
        line.chomp!
        next if line =~ /\A\s*\z/
        next if line =~ /\Abegin \d\d\d [^ ]/
        break if line =~ /\Aend\z/
        ret.concat line.unpack("u").first
      end
      ret
    end

    # str をそのまま返す
    def decode_plain(str)
      str
    end

  end
end
