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
    last_charset = nil
    words = []
    mime_word = false
    str.gsub(/\r?\n/, '').split(/(\s+)/).each do |s|
      s, cs, raw, pre, post = decode_word(s)
      if charset
        begin
          s = charset_converter.call(cs || charset, charset, s)
        rescue
          s = raw
          cs = nil
        end
      end
      if cs
        words.pop if mime_word and words.last =~ /\A\s*\z/
        mime_word = true
      elsif s !~ /\A\s*\z/
        mime_word = false
      end
      words.push pre if pre
      words.push s
      words.push post if post
    end
    begin
      ret = words.join
    rescue
      ret = words.map{|s| s.force_encoding('binary')}.join
    end
    ret
  end

  def decode_word(str)
    charset = nil
    if str =~ /\=\?([^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+)\?([QB])\?([^\? ]+)\?\=/i
      pre, post = $`, $'
      charset, encoding, enc_text = $1.downcase, $2.downcase, $3
      raw = str
      str = encoding == "q" ? q_decode(enc_text) : b_decode(enc_text)
      if String.method_defined? :force_encoding
        begin
          str.force_encoding(charset)
        rescue
          str.force_encoding('ascii-8bit')
        end
      end
    end
    [str, charset, raw, pre, post]
  end

  def q_decode(str)
    return str.gsub(/_/," ").gsub(/=\s*?$/,"=").unpack("M")[0]
  end

  def b_decode(str)
    return str.gsub(/[^A-Z0-9\+\/=]/i,"").unpack("m")[0]
  end

end
