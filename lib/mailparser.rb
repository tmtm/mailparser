#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/error"
require "mailparser/rfc2045"
require "mailparser/rfc2047"
require "mailparser/rfc2183"
require "mailparser/rfc2231"
require "mailparser/rfc2822"
require "mailparser/loose"
require "mailparser/conv_charset"

require "stringio"

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
          @parsed = RFC2047.decode(r, @opt[:output_charset])
        else
          @parsed = r
        end
      end
      class <<@parsed
        attr_accessor :raw
      end
      @parsed.raw = @raw
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
      @hash[name] = [] unless @hash.key? name
      @hash[name] << HeaderItem.new(name, body, @opt)
    end

    # パースした結果オブジェクトの配列を返す
    # name:: ヘッダ名(String)
    def [](name)
      return nil unless @hash.key? name
      return @parsed[name] if @parsed.key? name
      @parsed[name] = @hash[name].map{|h| h.parse}
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
    include RFC2231

    # src からヘッダ部を読み込み Header オブジェクトに保持する
    # src:: each_line イテレータを持つオブジェクト(ex. IO, String)
    # opt:: オプション(Hash)
    #  :skip_body::            本文をスキップする
    #  :text_body_only::       text/* type 以外の本文をスキップする
    #  :extract_message_type:: message/* type を展開する
    #  :decode_mime_header::   MIMEヘッダをデコードする
    #  :decode_mime_filename:: ファイル名を MIME デコードする
    #  :output_charset::       デコード出力文字コード(デフォルト: 変換しない)
    #  :strict::               RFC違反時に ParseError 例外を発生する
    #  :keep_raw::             生メッセージを保持する
    # boundary:: このパートの終わりを表す文字列の配列
    def initialize(src, opt={}, boundary=[])
      @src = src
      @line_buffered = false
      @opt = opt
      @boundary = boundary
      @from = @to = @cc = @subject = nil
      @type = @subtype = @charset = @content_transfer_encoding = @filename = nil
      @rawheader = ""
      @raw = ""
      @message = nil
      read_header
      read_body
      read_part
      if @header.key? "content-type" then
        @header["content-type"].each do |h|
          new = parse_param(h.params, @opt[:strict])
          new.each do |k,v|
            v.replace(ConvCharset.conv_charset(v.charset, @opt[:output_charset], v)) if v.charset and @opt[:output_charset] rescue nil
          end
          h.params.replace new
        end
      end
      if @header.key? "content-disposition" then
        @header["content-disposition"].each do |h|
          new = parse_param(h.params, @opt[:strict])
          new.each do |k,v|
            v.replace(ConvCharset.conv_charset(v.charset, @opt[:output_charset], v)) if v.charset and @opt[:output_charset] rescue nil
          end
          h.params.replace new
        end
      end
    end

    attr_reader :header, :body, :part, :last_line, :message, :rawheader, :raw

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
    # charset 属性がない場合は "us-ascii"
    def charset()
      return @charset if @charset
      if @header.key? "content-type" then
        c = @header["content-type"][0].params["charset"]
        @charset = c ? c.downcase : "us-ascii"
      else
        @charset = "us-ascii"
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
      @filename = RFC2047.decode(@filename, @opt[:output_charset]) if @opt[:decode_mime_filename] and @filename
      return @filename
    end

    private

    # ヘッダ部をパースする
    def read_header()
      @header = Header.new(@opt)
      headers = []
      each_line_with_delimiter(@boundary) do |line|
        break if line.chomp.empty?
        cont = line =~ /^\s/
        if (cont and headers.empty?) or (!cont and !line.include? ":") then
          ungetline
          break
        end
        if line =~ /^\s/ then
          headers.last << line
        else
          headers << line
        end
        @rawheader << line
      end
      headers.each do |h|
        name, body = h.split(/\s*:\s*/, 2)
        name.downcase!
        @header.add(name, body)
      end
    end

    # 本文を読む
    def read_body()
      @body = ""
      return if type == "multipart"
      unless @opt[:extract_message_type] and type == "message" then
        if @opt[:skip_body] or (@opt[:text_body_only] and type != "text")
          each_line_with_delimiter(@boundary){}       # 本文skip
          return
        end
      end
      each_line_with_delimiter(@boundary) do |line|
        @body << line
      end
      case content_transfer_encoding
      when "quoted-printable" then @body = RFC2045.qp_decode(@body)
      when "base64" then @body = RFC2045.b64_decode(@body)
      end
      if @opt[:output_charset] then
        @body = MailParser::ConvCharset.conv_charset(charset, @opt[:output_charset], @body) rescue @body
      end
      if @opt[:extract_message_type] and type == "message" and not @body.empty? then
        @message = Message.new(StringIO.new(@body), @opt)
      end
    end

    # 各パートの Message オブジェクトの配列を作成
    def read_part()
      @part = []
      return if type != "multipart"
      b = @header["content-type"][0].params["boundary"]
      bd = @boundary + ["--#{b}--", "--#{b}"]
      each_line_with_delimiter(bd){}  # skip preamble
      while @last_line == bd[-1] do
        m = Message.new(@src, @opt, bd)
        @part << m
        @raw << m.raw if @opt[:keep_raw]
        @last_line = m.last_line
      end
      each_line_with_delimiter(@boundary){} if @last_line == bd[-2] # skip epilogue
    end

    # 行毎にブロックを繰り返す
    # delim に含まれる行に一致した場合は中断
    def each_line_with_delimiter(delim=[])
      if @line_buffered then
        @line_buffered = false
        yield @last_line
      end
      @src.each_line do |line|
        @raw << line if @opt[:keep_raw]
        @last_line = line.chomp
        return if delim.include? @last_line
        yield line
      end
      return
    end

    # １行分 each_line_with_delimiter をなかったことに
    def ungetline()
      @line_bufferd = true
    end
  end
end
