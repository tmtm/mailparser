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

  # Header field
  class HeaderItem
    # @param [String] name header field name
    # @param [String] raw header field value
    # @param [Hash] opt options
    # @option opt [Boolean] :decode_mime_header (false) decode MIME header
    # @option opt [String] :output_charset (nil) output encoding name
    # @option opt [Boolean] :strict (false) raise ParseError exception when message is invalid
    def initialize(name, raw, opt={})
      @name = name
      @raw = raw
      @parsed = nil
      @opt = opt
    end

    # @return [String] raw field value
    attr_reader :raw

    # @return [header field value] parsed header object
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
        r = @raw.chomp.gsub(/\r?\n/, '').gsub(/\t/, ' ')
        if @opt[:decode_mime_header] then
          @parsed = RFC2047.decode(r, @opt)
        else
          @parsed = r
        end
      end
      if @parsed
        class <<@parsed
          attr_accessor :raw
        end
        @parsed.raw = @raw
      end

      # Content-Type, Content-Disposition parameter for RFC2231
      if ["content-type", "content-disposition"].include? @name
        new = RFC2231.parse_param @parsed.params, @opt
        @parsed.params.replace new
      end

      return @parsed
    end
  end

  # Header part
  class Header
    # @param [Hash] opt options
    # @option opt [Boolean] :decode_mime_header decode MIME header
    # @option opt [String] :output_charset output encoding name
    # @option opt [Boolean] :strict raise ParseError exception when message is invalid
    def initialize(opt={})
      @hash = {}
      @parsed = {}
      @raw = {}
      @opt = opt
    end

    # add header field
    # @param [String] name header field name
    # @param [String] body header field value
    # @return [void]
    def add(name, body)
      name = name.downcase
      @hash[name] = [] unless @hash.key? name
      @hash[name] << HeaderItem.new(name, body, @opt)
    end

    # header field value
    # @param [String] name header field name
    # @return [Array<header field value>]
    def [](name)
      return nil unless @hash.key? name
      return @parsed[name] if @parsed.key? name
      @parsed[name] = @hash[name].map{|h| h.parse}.compact
      return @parsed[name]
    end

    # @param [String] name header field name
    # @return [Array<String>] raw header value
    def raw(name)
      return nil unless @hash.key? name
      return @raw[name] if @raw.key? name
      @raw[name] = @hash[name].map{|h| h.raw}
      return @raw[name]
    end

    # @return [Array<String>] header names
    def keys()
      return @hash.keys
    end

    # @param [String] name header field name
    # @return [Boolean] true if header field exists
    def key?(name)
      return @hash.key?(name)
    end

    # repeat block for each header field
    # @yield [key, value]
    # @yieldparam [String] key header field name
    # @yieldparam [header field value] value header field value
    # @return [void]
    def each()
      @hash.each do |k, v|
        yield k, self[k]
      end
    end
  end

  # Mail message
  # @example
  #  require 'mailparser'
  #  f = File.open('hoge.eml')
  #  m = MailParser::Message.new(f, :output_charset=>'utf-8')
  #  m.subject  #=> String
  #  m.body     #=> String
  #  m.part     #=> Array of Mailparser::Message
  class Message
    # @param [String, File, MmapScanner, #read] src source object
    # @param [Hash] opt options
    # @option opt [Boolean] :decode_mime_header (false) decode MIME header
    # @option opt [Boolean] :decode_mime_filename (false) decode MIME encoded filename
    # @option opt [Boolean] :output_charset (nil) output encoding
    # @option opt [Boolean] :strict (false) raise ParseError exception when message is invalid
    # @option opt [Proc, Method, #call] :charset_converter (nil) charset converter. default is MailParser::ConvCharset.conv_charset
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
    # @!attribute [r] header
    #   @return [MailParser::Header]
    # @!attribute [r] part
    #   @return [Array<MailParser::Message>]

    # @return [String] message body decoded and converted charset
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

    # @return [String] message body decoded and not converted charset
    def body_preconv
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

    # @return [MailParser::Message] body type is message/*
    # @return [nil] when type is not message/*
    def message
      return nil unless type == "message"
      if ['7bit', '8bit'].include? content_transfer_encoding
        @rawbody.pos = 0
        return Message.new(@rawbody, @opt)
      end
      return Message.new(body_preconv, @opt)
    end

    # @return [MailParser::RFC2822::Mailbox] From field
    # @return [nil] when From field don't exist
    def from()
      return @from if @from
      if @header.key? "from" then
        @from = @header["from"][0][0]
      else
        @from = nil
      end
      return @from
    end

    # @return [Array<MailParser::RFC2822::Mailbox>] To field
    # @return [nil] when To field don't exist
    def to()
      return @to if @to
      if @header.key? "to" then
        @to = @header["to"].flatten
      else
        @to = []
      end
      return @to
    end

    # @return [Array<MailParser::RFC2822::Mailbox>] Cc field
    # @return [nil] when Cc field don't exist
    def cc()
      return @cc if @cc
      if @header.key? "cc" then
        @cc = @header["cc"].flatten
      else
        @cc = []
      end
      return @cc
    end

    # @return [String] Subject field
    def subject()
      return @subject if @subject
      if @header.key? "subject" then
        @subject = @header["subject"].join(" ")
      else
        @subject = ""
      end
      return @subject
    end

    # @return [String] Content-Type main type as lower-case
    def type()
      return @type if @type
      if @header.key? "content-type" then
        @type = @header["content-type"][0].type
      else
        @type = "text"
      end
      return @type
    end

    # @return [String] Content-Type sub type as lower-case
    def subtype()
      return @subtype if @subtype
      if @header.key? "content-type" then
        @subtype = @header["content-type"][0].subtype
      else
        @subtype = "plain"
      end
      return @subtype
    end

    # @return [String] Content-Type charset attribute as lower-case
    # @return [nil] when charset attribute don't exist
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

    # @return [Boolean] true if multipart type
    def multipart?()
      return type == "multipart"
    end

    # @return [String] Content-Transfer-Encoding mechanism. default is "7bit"
    def content_transfer_encoding()
      return @content_transfer_encoding if @content_transfer_encoding
      if @header.key? "content-transfer-encoding" then
        @content_transfer_encoding = @header["content-transfer-encoding"][0].mechanism
      else
        @content_transfer_encoding = "7bit"
      end
      return @content_transfer_encoding
    end

    # @return [String] Content-Disposition filename attribute or Content-Type name attribute
    # @return [nil] when filename attribute don't exist
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

    # @return [String] raw message
    def raw
      return @src.to_s
    end

    # @return [String] raw header
    def rawheader
      @rawheader.to_s
    end

    # @return [String] raw body
    def rawbody
      @rawbody.to_s
    end

    private

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
      @src.scan(/\r?\n/)        # skip delimiter line
      @rawbody = @src.rest
    end

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

    def decode_plain(str)
      str
    end

  end
end
