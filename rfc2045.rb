#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "rfc2822"
require "rfc2045/parser"

class RFC2045

  class ParseError < StandardError
  end

  HEADER_TYPE = {
    "content-type"              => :CONTENT_TYPE,
    "content-description"       => :UNSTRUCTURED,
    "content-transfer-encoding" => :CONTENT_TRANSFER_ENCODING,
    "content-id"                => [RFC2822, :MSG_ID],
    "mime-version"              => :MIME_VERSION,
  }

  class ContentType
    def initialize(type, subtype, params)
      @type, @subtype, @params = type.downcase, subtype.downcase, params
    end

    attr_reader :type, :subtype, :params
  end

  class ContentTransferEncoding
    def initialize(mechanism)
      @mechanism = mechanism.downcase
    end

    attr_reader :mechanism
  end

  def self.parse(name, value)
    htype = HEADER_TYPE[name.downcase] || :UNSTRUCTURED
    if htype == :UNSTRUCTURED then
      return value.chomp
    end
    if htype.is_a? Array then
      parser = htype[0]::Parser.new
      parser.parse(htype[1], value)
    else
      parser = Parser.new
      parser.parse(htype, value)
    end
  end
end
