# $Id$

require "rfc2822obs"
require "rfc2045"

# メールをパースする。
# 
#   m = MailParser.new
#   m.parse(src)
#   m.header => #<MailParser::Header>
#   m.body => パースされた本文文字列
#   m.part => [#<Mailparser>, ...]
# 
class MailParser
  include RFC2822obs
  include RFC2045

  HEADER_PARSER = {
    "date"                      => RFC2822obs,
    "from"                      => RFC2822obs,
    "sender"                    => RFC2822obs,
    "reply-to"                  => RFC2822obs,
    "to"                        => RFC2822obs,
    "cc"                        => RFC2822obs,
    "bcc"                       => RFC2822obs,
    "message-id"                => RFC2822obs,
    "in-reply-to"               => RFC2822obs,
    "references"                => RFC2822obs,
    "subject"                   => RFC2822obs,
    "comments"                  => RFC2822obs,
    "keywords"                  => RFC2822obs,
    "resent-date"               => RFC2822obs,
    "resent-from"               => RFC2822obs,
    "resent-sender"             => RFC2822obs,
    "resent-to"                 => RFC2822obs,
    "resent-cc"                 => RFC2822obs,
    "resent-bcc"                => RFC2822obs,
    "resent-message-id"         => RFC2822obs,
    "return-path"               => RFC2822obs,
    "received"                  => RFC2822obs,
    "content-type"              => RFC2045,
    "content-description"       => RFC2045,
    "content-transfer-encoding" => RFC2045,
    "content-id"                => RFC2045,
    "mime-version"              => RFC2045,
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
      @hash[name].map{|h| h.parse}
    end

    # 生ヘッダ値文字列の配列を返す
    # name:: ヘッダ名(String)
    def raw(name)
      return nil unless @hash.key? name
      @hash[name].map{|h| h.raw}
    end

    # ヘッダ名の配列を返す
    def keys()
      return @hash.keys
    end

    # 各ヘッダについてブロックを繰り返す
    # ブロック引数は、ヘッダ名, [MailParser::Headerオブジェクト,...]
    def each()
      @hash.each do |k, v|
        yield k, v
      end
    end
  end

  class Message
    # src からヘッダ部を読み込み Header オブジェクトに保持する
    # src:: each_line イテレータを持つオブジェクト(ex. IO, String)
    def initialize(src)
      @header = Header.new
      headers = []
      src.each_line do |line|
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
