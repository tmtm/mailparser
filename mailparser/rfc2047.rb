#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "strscan"

class MailParser
end

module MailParser::RFC2047
  module_function

  def decode(str)
    ret = []
    while str =~ /\=\?([^\(\)\<\>\@\,\;\:\"\/\[\]\?\.\=]+)\?([QB])\?([^\? ]+)\?\=/ni do
      pre, charset, encoding, enc_text, after = $`, $1.downcase, $2.downcase, $3, $'
      if pre.nil? or not pre.empty? then
        class << pre
          attr_accessor :charset
        end
        ret << pre
      end
      s = encoding == "q" ? q_decode(enc_text) : b_decode(enc_text)
      class << s
        attr_accessor :charset
      end
      s.charset = charset
      ret << s
      str = after
    end
    if not str.empty? then
      class << str
        attr_accessor :charset
      end
      ret << str
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
