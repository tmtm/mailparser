# -*- coding: utf-8 -*-
# Copyright (C) 2006-2010 TOMITA Masahiro
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
    # src:: gets メソッドを持つオブジェクト(ex. IO, StringIO)
    # opt:: オプション(Hash)
    #  :skip_body::            本文をスキップする
    #  :text_body_only::       text/* type 以外の本文をスキップする
    #  :extract_message_type:: message/* type を展開する
    #  :decode_mime_header::   MIMEヘッダをデコードする
    #  :decode_mime_filename:: ファイル名を MIME デコードする
    #  :output_charset::       デコード出力文字コード(デフォルト: 変換しない)
    #  :strict::               RFC違反時に ParseError 例外を発生する
    #  :keep_raw::             生メッセージを保持する
    #  :charset_converter::    文字コード変換用 Proc または Method
    #  :use_file::             body, raw がこのサイズを超えたらメモリではなくファイルを使用する
    # boundary:: このパートの終わりを表す文字列の配列
    def initialize(src, opt={}, boundary=[])
      src = src.is_a?(String) ? StringIO.new(src) : src
      @dio = DelimIO.new(src, boundary, opt[:keep_raw], opt[:use_file])
      @opt = opt
      @boundary = boundary
      @from = @to = @cc = @subject = nil
      @type = @subtype = @charset = @content_transfer_encoding = @filename = nil
      @rawheader = ''
      @message = nil
      @body = @body_preconv = DataBuffer.new(opt[:use_file])
      @part = []
      opt[:charset_converter] ||= ConvCharset.method(:conv_charset)

      read_header
      read_body
      read_part
    end

    attr_reader :header, :part, :message

    # 内部で作成された DataBuffer#io を close する。
    def close
      @body.io.close rescue nil
      @body_preconv.io.close rescue nil
      @dio.keep_buffer.io.close rescue nil
    end

    def body
      @body.str
    end

    def body_io
      @body.io
    end

    def body_preconv
      @body_preconv.str
    end

    def body_preconv_io
      @body_preconv.io
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
      @dio.keep_buffer.str
    end

    # 生ヘッダを返す
    def rawheader
      @rawheader
    end

    private

    # ヘッダ部をパースする
    # return:: true: 継続行あり
    def read_header()
      @header = Header.new(@opt)
      headers = []
      @dio.each_line do |line|
        break if line.chomp.empty?
        cont = line =~ /^[ \t]/
        if (cont and headers.empty?) or (!cont and !line.include? ":") then
          @dio.ungets
          break
        end
        if line =~ /^[ \t]/ then
          headers[-1] += line    # :keep_raw 時の行破壊を防ぐため`<<'は使わない
        else
          headers << line
        end
        @rawheader << line
      end
      headers.each do |h|
        name, body = h.split(/\s*:\s*/n, 2)
        @header.add(name, body)
      end
    end

    # 本文を読む
    def read_body()
      return if type == "multipart" or @dio.eof?
      unless @opt[:extract_message_type] and type == "message" then
        if @opt[:skip_body] or (@opt[:text_body_only] and type != "text")
          @dio.each_line{}         # 本文skip
          return
        end
      end
      buff = DataBuffer.new(@opt[:use_file])
      @dio.each_slice(100) do |lines|
        buff << lines.join
      end
      buff.chomp! unless @dio.real_eof?
      decoder = case content_transfer_encoding
                when "quoted-printable"
                  RFC2045.method(:qp_decode)
                when "base64"
                  RFC2045.method(:b64_decode)
                when "uuencode", "x-uuencode", "x-uue"
                  self.method(:decode_uuencode)
                else
                  self.method(:decode_plain)
                end
      buff.io.each_slice(100) do |lines|
        @body << decoder.call(lines.join)
      end
      buff.io.close
      @body_preconv = @body
      if type == 'text' and charset and @opt[:output_charset] then
        new_body = DataBuffer.new(@opt[:use_file])
        begin
          if @opt[:use_file] and @body.size > @opt[:use_file]
            newline = @opt[:charset_converter].call(@opt[:output_charset], charset, "\n")
            @body.io.each_line(newline) do |line|
              new_body << @opt[:charset_converter].call(charset, @opt[:output_charset], line)
            end
          else
            new_body << @opt[:charset_converter].call(charset, @opt[:output_charset], @body.str)
          end
          @body = new_body
        rescue
          # ignore
        end
      end
      if @opt[:extract_message_type] and type == "message" and not @body.empty? then
        @message = Message.new(@body.io, @opt)
      end
    end

    # 各パートの Message オブジェクトの配列を作成
    def read_part()
      return if type != "multipart" or @dio.eof?
      b = @header["content-type"][0].params["boundary"]
      bd = ["--#{b}--", "--#{b}"]
      last_line = @dio.each_line(bd){}        # skip preamble
      while last_line and last_line.chomp == bd.last
        m = Message.new @dio, @opt, @boundary+bd
        @part << m
        last_line = @dio.gets                 # read boundary
      end
      @dio.each_line{}                        # skip epilogue
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

  # 特定の行を EOF とみなして gets が動く IO モドキ
  class DelimIO
    include Enumerable

    # src:: IO または StringIO
    # delim:: 区切り行の配列
    # keep:: 全行保存
    # use_file:: keep_buffer がこのサイズを超えたらメモリではなくファイルを使用する
    def initialize(src, delim=nil, keep=false, use_file=nil)
      @src = src
      @delim_re = delim && !delim.empty? && Regexp.new(delim.map{|d|"\\A#{Regexp.quote(d)}\\r?\\Z"}.join("|"))
      @keep = keep
      @keep_buffer = DataBuffer.new(use_file)
      @line_buffer = nil
      @eof = false                # delim に達したら真
      @real_eof = false
      @last_read_line = nil
    end

    attr_reader :keep_buffer

    # 行毎にブロックを繰り返す。
    # delim に一致した場合は中断
    # delim:: 区切り文字列の配列
    # return:: delimに一致した行 or nil(EOFに達した)
    def each_line(delim=nil)
      return if @eof
      while line = gets
        return line if delim and delim.include? line.chomp
        yield line
      end
      nil
    end
    alias each each_line

    # 1行読み込む。@delim_re に一致する行で EOF
    def gets
      return if @eof
      if @line_buffer
        line = @line_buffer
        @line_buffer = nil
      else
        line = @src.gets
        unless line  # EOF
          @keep_buffer << @last_read_line if @keep and @last_read_line
          @eof = @real_eof = true
          return
        end
      end
      if @delim_re and @delim_re.match line
        @keep_buffer << @last_read_line if @keep and @last_read_line
        @src.ungets
        @eof = true
        return
      end
      @keep_buffer << @last_read_line if @keep and @last_read_line
      @last_read_line = line
      line
    end

    def ungets
      raise "preread line nothing" unless @last_read_line
      @eof = false
      @line_buffer = @last_read_line
      @last_read_line = nil
    end

    def eof?
      @eof
    end

    def real_eof?
      @src.is_a?(DelimIO) ? @src.real_eof? : @real_eof
    end

  end

  # 通常はメモリにデータを保持し、それ以上はファイル(Tempfile)に保持するためのクラス
  class DataBuffer
    # limit:: データがこのバイト数を超えたらファイルに保持する。nil の場合は無制限。
    def initialize(limit)
      @limit = limit
      @buffer = StringIO.new
    end

    # バッファに文字列を追加する
    def <<(str)
      if @limit and @buffer.is_a? StringIO and @buffer.size+str.size > @limit
        file = Tempfile.new 'mailparser_databuffer'
        file.unlink rescue nil
        file.write @buffer.string
        @buffer = file
      end
      @buffer << str
    end

    # バッファ内のデータを返す
    def str
      if @buffer.is_a? StringIO
        @buffer.string
      else
        @buffer.rewind
        @buffer.read
      end
    end

    # IOオブジェクト(のようなもの)を返す
    def io
      @buffer.rewind
      @buffer
    end

    # データの大きさを返す
    def size
      @buffer.pos
    end

    # 末尾が改行文字(\r\n or \n)の場合に削除する
    def chomp!
      size = [@buffer.size, 2].min
      @buffer.seek(-size, IO::SEEK_END)
      case @buffer.read(2)
      when "\r\n" then @buffer.truncate(@buffer.pos-2)
      when /\n\z/ then @buffer.truncate(@buffer.pos-1)
      end
      @buffer.seek 0, IO::SEEK_END
    end

    # バッファが空かどうかを返す
    def empty?
      @buffer.pos == 0
    end
  end
end
