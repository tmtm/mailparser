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
    last_charset = nil
    ret = ""
    split_decode(str, charset_converter, charset).each do |s, cs|
      s2 = s
      ret << " " if last_charset.nil? or cs.nil?
      ret << s2
      last_charset = cs
    end
    return ret.strip
  end

  def split_decode(str, charset_converter=nil, output_charset=nil)
    ret = []
    while str =~ /\=\?([^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+)\?([QB])\?([^\? ]+)\?\=/i do
      raw = $&
      pre, charset, encoding, enc_text, after = $`, $1.downcase, $2.downcase, $3, $'
      ret << [pre.strip, nil] unless pre.strip.empty?
      s = encoding == "q" ? q_decode(enc_text) : b_decode(enc_text)
      if String.method_defined? :force_encoding
        begin
          s.force_encoding(charset)
        rescue
          s.force_encoding('ascii-8bit')
        end
      end
      begin
        if output_charset
          if charset_converter
            s = charset_converter.call(charset, output_charset, s)
          else
            s = MailParser::ConvCharset.conv_charset(charset, output_charset, s)
          end
        end
      rescue
        s = raw
        charset = nil
      end
      ret << [s, charset]
      str = after
    end
    ret << [str.strip, nil] unless str.empty?
    return ret
  end

  def q_decode(str)
    return str.gsub(/_/," ").gsub(/=\s*?$/,"=").unpack("M")[0]
  end

  def b_decode(str)
    return str.gsub(/[^A-Z0-9\+\/=]/i,"").unpack("m")[0]
  end

end
