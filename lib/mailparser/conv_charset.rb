# Copyright (C) 2007-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "iconv"
require "nkf"

class MailParser::ConvCharset
  CHARSET = {
    "sjis"      => "cp932",
    "x-sjis"    => "cp932",
    "shift_jis" => "cp932",
    "shift-jis" => "cp932",
  }
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
