#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "rfc2045"
require "rfc2183"
require "rfc2231"
require "rfc2822"

# メールをパースする。
# 
#   m = MailParser.new
#   m.parse(src)
#   m.header => #<MailParser::Header>
#   m.body => パースされた本文文字列
#   m.part => [#<Mailparser>, ...]
# 
class MailParser
  include RFC2045, RFC2183, RFC2822

  class ParseError < StandardError
  end

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
    "subject"                   => RFC2822,
    "comments"                  => RFC2822,
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
    "content-description"       => RFC2045,
    "content-transfer-encoding" => RFC2045,
    "content-id"                => RFC2045,
    "mime-version"              => RFC2045,
    "content-disposition"       => RFC2183,
  }

  # opt:: オプション(Hash)
  #  :skip_body:: 本文をスキップする
  #  :text_body_only:: text/* type 以外の本文をスキップする
  #  :extract_message_type:: message/* type を展開する
  def initialize(opt={})
    @opt = opt
  end

  # Message オブジェクトを返す
  # src:: each_line イテレータを持つオブジェクト(ex. IO, String)
  def parse(src)
    Message.new(src, @opt)
  end

  # 単一のヘッダ
  class HeaderItem
    # name:: ヘッダ名(String)
    # raw:: ヘッダ値(String)
    def initialize(name, raw)
      @name = name
      @raw = raw
      @parsed = nil
    end

    attr_reader :raw

    # パースした結果オブジェクトを返す
    def parse()
      return @parsed if @parsed
      if HEADER_PARSER.key? @name then
        @parsed = HEADER_PARSER[@name].parse(@name, @raw)
      else
        @parsed = @raw
      end
      return @parsed
    end
  end

  # 同じ名前を持つヘッダの集まり
  class Header
    def initialize()
      @hash = Hash.new{|h,k| h[k] = []}
      @parsed = {}
      @raw = {}
    end

    # name ヘッダに body を追加する
    # name:: ヘッダ名(String)
    # body:: ヘッダ値(String)
    def add(name, body)
      @hash[name] << HeaderItem.new(name, body)
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
    # ブロック引数は、[ヘッダ名, [MailParser::Headerオブジェクト,...]]
    def each()
      @hash.each do |k, v|
        yield k, v
      end
    end
  end

  class Message
    include RFC2231

    # src からヘッダ部を読み込み Header オブジェクトに保持する
    # src:: each_line イテレータを持つオブジェクト(ex. IO, String)
    # boundary:: このパートの終わりを表す文字列の配列
    def initialize(src, opt, boundary=[])
      @src = src
      @opt = opt
      @boundary = boundary
      read_header
      read_body
      read_part
      if @header.key? "content-type" then
        @header["content-type"].each do |h|
          h.params.replace parse_param(h.params)
        end
      end
      @type = @subtype = @charset = @content_transfer_encoding = @filename = nil
    end

    attr_reader :header, :body, :part, :last_line

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
        @charset = @header["content-type"][0].params["charset"].downcase
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
      return @filename
    end

    private

    # ヘッダ部をパースする
    def read_header()
      @header = Header.new
      headers = []
      each_line_with_delimiter(@boundary) do |line|
        break if line.chomp.empty?
        if line =~ /^\s/ and headers.size > 0 then
          headers[-1] << line
        else
          headers << line
        end
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
      if @opt[:skip_body] or (@opt[:text_body_only] and type != "text")
        each_line_with_delimiter(@boundary){}
      else
        each_line_with_delimiter(@boundary) do |line|
          @body << line
        end
        case content_transfer_encoding
        when "quoted-printable" then @body = RFC2045.qp_decode(@body)
        when "base64" then @body = RFC2045.b64_decode(@body)
        end
      end
    end

    # 各パートの Message オブジェクトの配列を作成
    def read_part()
      @part = []
      return if type != "multipart"
      b = @header["content-type"][0].params["boundary"]
      bd = @boundary + ["--#{b}--", "--#{b}"]
      each_line_with_delimiter(bd){}  # skip preamble
      ll = last_line
      while ll == bd[-1] do
        m = Message.new(@src, @opt, bd)
        @part << m
        ll = m.last_line
      end
      each_line_with_delimiter(@boundary){} if @last_line == bd[-2] # skip epilogue
    end

    # 行毎にブロックを繰り返す
    # delim に含まれる行に一致した場合は中断
    def each_line_with_delimiter(delim=[])
      @src.each_line do |line|
        @last_line = line.chomp
        return if delim.include? @last_line
        yield line
      end
      return
    end
  end
end
