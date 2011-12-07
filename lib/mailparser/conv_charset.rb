# Copyright (C) 2007-2011 TOMITA Masahiro
# mailto:tommy@tmtm.org

module MailParser
end

class MailParser::ConvCharset
  CHARSET = {
    "sjis"        => "cp932",
    "x-sjis"      => "cp932",
    "shift_jis"   => "cp932",
    "shift-jis"   => "cp932",
    "iso-2022-jp" => "cp50221",
  }
  if String.method_defined? 'encode'
    def self.conv_charset(from, to, str)
      from = CHARSET[from.downcase] || from.downcase
      to = CHARSET[to.downcase] || to.downcase
      str.encode(to, from, :invalid=>:replace, :undef=>:replace, :replace=>'?')
    end
  else
    require "iconv"
    require "nkf"

    def self.conv_charset(from, to, str)
      from = CHARSET[from.downcase] || from.downcase
      to = CHARSET[to.downcase] || to.downcase
      s = str
      if from == "iso-2022-jp" then
        s = NKF.nkf("-m0Jxs", str)
        from = "cp932"
      end
      if to == "iso-2022-jp" then
        return NKF.nkf("-m0Sxj", Iconv.iconv("cp932", from, s)[0])
      end
      return Iconv.iconv(to, from, s)[0]
    end
  end
end
