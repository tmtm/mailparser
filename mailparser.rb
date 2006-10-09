# $Id$

require "rfc2822obs"

class MailParser

  HEADER_PARSER = {
    "date"              => RFC2822obs,
    "from"              => RFC2822obs,
    "sender"            => RFC2822obs,
    "reply-to"          => RFC2822obs,
    "to"                => RFC2822obs,
    "cc"                => RFC2822obs,
    "bcc"               => RFC2822obs,
    "message-id"        => RFC2822obs,
    "in-reply-to"       => RFC2822obs,
    "references"        => RFC2822obs,
    "subject"           => RFC2822obs,
    "comments"          => RFC2822obs,
    "keywords"          => RFC2822obs,
    "resent-date"       => RFC2822obs,
    "resent-from"       => RFC2822obs,
    "resent-sender"     => RFC2822obs,
    "resent-to"         => RFC2822obs,
    "resent-cc"         => RFC2822obs,
    "resent-bcc"        => RFC2822obs,
    "resent-message-id" => RFC2822obs,
    "return-path"       => RFC2822obs,
    "received"          => RFC2822obs,
    "content-type"      => RFC2045,
    "content-description" => RFC2045,
    "content-transfer-encoding" => RFC2045,
    "content-id"        => RFC2045,
    "mime-version"      => RFC2045,
  }

  class Header
    def initialize(name, raw)
      @name = name
      @raw = raw
      @parsed = nil
    end

    attr_reader :raw

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

  class HeaderList
    def initialize()
      @hash = Hash.new{|h,k| h[k] = []}
    end

    def add(name, body)
      @hash[name] << Header.new(name, body)
    end

    def [](name)
      return nil unless @hash.key? name
      @hash[name].map{|h| h.parse}
    end
  end

  def initialize(src, opt={})
    @src = src
    @opt = opt
    @header = HeaderList.new
    parse
  end

  attr_reader :header

  def parse()
    headers = []
    @src.each do |line|
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

end
