# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "strscan"
require "iconv"
require "nkf"
require "mailparser/conv_charset"

module MailParser
end

module MailParser::RFC2047

  class String < ::String
    @@charset_converter = Proc.new{|f,t,s| MailParser::ConvCharset.conv_charset(f,t,s)}
    def initialize(str, charset=nil, raw=nil, charset_converter=nil)
      super(str)
      @charset = charset
      @raw = raw || str
      @charset_converter = charset_converter || @@charset_converter
    end
    attr_reader :charset
    attr_reader :raw

    def conv_charset(to_charset)
      if @charset and to_charset
        @charset_converter.call @charset, to_charset, self
      else
        self
      end
    end
  end

  module_function

  def decode(str, opt=nil)
    if opt.is_a? Hash
      charset = opt[:output_charset]
      charset_converter = opt[:charset_converter]
    else
      charset = opt
    end
    last_charset = nil
    ret = ""
    split_decode(str, charset_converter).each do |s|
      begin
        s2 = charset && s.charset ? s.conv_charset(charset) : s
        cs = s.charset
      rescue Iconv::Failure
        s2 = s.raw
        cs = nil
      end
      ret << " " if last_charset.nil? or cs.nil?
      ret << s2
      last_charset = cs
    end
    return ret.strip
  end

  def split_decode(str, charset_converter=nil)
    ret = []
    while str =~ /\=\?([^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+)\?([QB])\?([^\? ]+)\?\=/ni do
      raw = $&
      pre, charset, encoding, enc_text, after = $`, $1.downcase, $2.downcase, $3, $'
      ret << String.new(pre.strip) unless pre.strip.empty?
      s = encoding == "q" ? q_decode(enc_text) : b_decode(enc_text)
      ret << String.new(s, charset, raw, charset_converter)
      str = after
    end
    ret << String.new(str.strip) unless str.empty?
    return ret
  end

  def q_decode(str)
    return str.gsub(/_/," ").gsub(/=\s*?$/,"=").unpack("M")[0]
  end

  def b_decode(str)
    return str.gsub(/[^A-Z0-9\+\/=]/i,"").unpack("m")[0]
  end

end
