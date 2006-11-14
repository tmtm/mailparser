#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

class MailParser
end

require "mailparser/rfc2183/parser"

module MailParser::RFC2183
  class ParseError < StandardError
  end

  HEADER_TYPE = {
    "content-disposition"      => :CONTENT_DISPOSITION,
  }

  class ContentDisposition
    def initialize(type, params)
      @type, @params = type.downcase, params
    end

    attr_reader :type, :params
  end

  module_function

  def parse(name, value)
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
