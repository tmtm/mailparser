# $Id$

require "rfc2822"
require "rfc2045"
require "rfc2183"

# メールをパースする。
# 
#   m = MailParser.new
#   m.parse(src)
#   m.header => #<MailParser::Header>
#   m.body => パースされた本文文字列
#   m.part => [#<Mailparser>, ...]
# 
class MailParser
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
    # src からヘッダ部を読み込み Header オブジェクトに保持する
    # src:: each_line イテレータを持つオブジェクト(ex. IO, String)
    # boundary:: このパートの終わりを表す文字列の配列
    def initialize(src, boundary=[])
      @src = src
      @boundary = boundary
      read_header
      read_body
      read_part
    end

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

    attr_reader :header

    # Content-Type の type を返す。
    # Content-Type がない場合は "text"
    def type()
      if @header.key? "content-type" then
        return @header["content-type"][0].type
      else
        return "text"
      end
    end

    # Content-Type の subtype を返す。
    # Content-Type がない場合は "plain"
    def subtype()
      if @header.key? "content-type" then
        return @header["content-type"][0].subtype
      else
        return "plain"
      end
    end

    # マルチパートメッセージかどうかを返す
    def multipart?()
      return type == "multipart"
    end

    # 本文を返す。
    def read_body()
      return if type == "multipart"
      @body = ""
      each_line_with_delimiter(@boundary) do |line|
        @body << line
      end
      return @body
    end

    attr_reader :body

    # 各パートの Message オブジェクトの配列を返す。
    def read_part()
      return if type != "multipart"
      @part = []
      b = @header["content-type"][0].params["boundary"]
      bd = @boundary + ["--#{b}--", "--#{b}"]
      each_line_with_delimiter(bd){}  # skip preamble
      ll = last_line
      while ll == bd[-1] do
        m = Message.new(@src, bd)
        @part << m
        ll = m.last_line
      end
      each_line_with_delimiter(@boundary){} if @last_line == bd[-2] # skip epilogue
      return @part
    end

    attr_reader :part

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
    attr_reader :last_line
  end

  # opt:: オプション(Hash)
  def initialize(opt={})
    @opt = opt
  end

  # Message オブジェクトを返す
  # src:: each_line イテレータを持つオブジェクト(ex. IO, String)
  def parse(src)
    Message.new(src)
  end
end
