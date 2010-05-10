# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/error"
require "mailparser/rfc2183/parser"

module MailParser::RFC2183
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

  def parse(name, value, opt={})
    htype = HEADER_TYPE[name.downcase]
    unless htype then
      return value.chomp
    end
    if htype.is_a? Array then
      htype[0]::Parser.new.parse(htype[1], value)
    else
      Parser.new.parse(htype, value)
    end
  end
end
