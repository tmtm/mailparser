# coding: ascii-8bit
# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "strscan"
require "mailparser/conv_charset"

module MailParser
end

module MailParser::RFC2047

  module_function

  def decode(str, opt=nil)
    if opt.is_a? Hash
      charset = opt[:output_charset]
      charset_converter = opt[:charset_converter]
    else
      charset = opt
    end
    charset_converter ||= MailParser::ConvCharset.method(:conv_charset)
    words = []
    ss = StringScanner.new(str.gsub(/\r?\n/, ''))
    until ss.eos?
      if s = ss.scan(/\=\?[^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+\?[QB]\?[^\? ]+\?\=/i)
        begin
          s = Encoded.new s, charset, charset_converter
          words.pop if words.length >= 2 and words[-1].is_a? Space and words[-2].is_a? Encoded
        rescue
          # ignore
        end
        words.push s
      elsif s = ss.scan(/\s+/)
        words.push Space.new(s)
      elsif s = ss.scan(/[^\s=]+/)
        words.push s
      else
        words.push ss.scan(/./)
      end
    end
    begin
      ret = words.join
    rescue
      ret = words.map{|w| w.to_s.force_encoding('binary')}.join
    end
    charset ? charset_converter.call(charset, charset, ret) : ret
  end

  def q_decode(str)
    return str.gsub(/_/," ").gsub(/=\s*?$/,"=").unpack("M")[0]
  end

  def b_decode(str)
    return str.gsub(/[^A-Z0-9\+\/=]/i,"").unpack("m")[0]
  end

  class Space < String
  end

  class Encoded
    def initialize(str, charset, converter)
      _, cs, encoding, enc_text, = str.split(/\?/)
      str = encoding.downcase == 'q' ? MailParser::RFC2047.q_decode(enc_text) : MailParser::RFC2047.b_decode(enc_text)
      @decoded = converter.call(cs, charset||cs, str)
    end

    def to_s
      @decoded
    end
  end
end
