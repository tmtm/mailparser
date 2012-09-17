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
    last_charset = nil
    ret = ""
    ret.force_encoding(charset) if String.method_defined? :force_encoding and charset
    split_decode(str) do |s, cs, raw|
      if charset
        begin
          s = charset_converter.call(cs || charset, charset, s)
        rescue
          s = raw
          cs = nil
        end
      end
      ret << " " if last_charset.nil? or cs.nil?
      ret << s
      last_charset = cs
    end
    return ret.strip
  end

  def split_decode(str)
    while str =~ /\=\?([^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+)\?([QB])\?([^\? ]+)\?\=/i do
      raw = $&
      pre, charset, encoding, enc_text, after = $`, $1.downcase, $2.downcase, $3, $'
      s = pre.strip
      yield s, nil, raw unless s.empty?
      s = encoding == "q" ? q_decode(enc_text) : b_decode(enc_text)
      if String.method_defined? :force_encoding
        begin
          s.force_encoding(charset)
        rescue
          s.force_encoding('ascii-8bit')
        end
      end
      yield s, charset, raw
      str = after
    end
    s = str.strip
    yield s, nil, raw unless s.empty?
  end

  def q_decode(str)
    return str.gsub(/_/," ").gsub(/=\s*?$/,"=").unpack("M")[0]
  end

  def b_decode(str)
    return str.gsub(/[^A-Z0-9\+\/=]/i,"").unpack("m")[0]
  end

end
