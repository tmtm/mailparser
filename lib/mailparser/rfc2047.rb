#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "strscan"
require "iconv"
require "nkf"
require "mailparser/conv_charset"

module MailParser
end

module MailParser::RFC2047

  class String < ::String
    def initialize(str, charset=nil, raw=nil)
      super(str)
      @charset = charset
      @raw = raw || str
    end
    attr_reader :charset
    attr_reader :raw

    def conv_charset(charset)
      return MailParser::ConvCharset.conv_charset(@charset, charset, self)
    end
  end

  module_function

  def decode(str, charset=nil)
    last_charset = nil
    ret = ""
    split_decode(str).each do |s|
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

  def split_decode(str)
    ret = []
    while str =~ /\=\?([^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+)\?([QB])\?([^\? ]+)\?\=/ni do
      raw = $&
      pre, charset, encoding, enc_text, after = $`, $1.downcase, $2.downcase, $3, $'
      if pre.nil? or not pre.sub(/\s+/,"").empty? then
        ret << String.new(pre.strip)
      end
      s = encoding == "q" ? q_decode(enc_text) : b_decode(enc_text)
      ret << String.new(s, charset, raw)
      str = after
    end
    if not str.empty? then
      ret << String.new(str.strip)
    end
    return ret
  end

  def q_decode(str)
    return str.gsub(/_/," ").gsub(/=\s*$/,"=").unpack("M")[0]
  end

  def b_decode(str)
    return str.gsub(/[^A-Z0-9\+\/=]/i,"").unpack("m")[0]
  end

end
