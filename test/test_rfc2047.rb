#
# $Id$
#
# Copyright (C) 2006-2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/rfc2047"
require "test/unit"

class TC_RFC2047 < Test::Unit::TestCase
  def test_q_decode_ascii()
    assert_equal("hoge", MailParser::RFC2047.q_decode("hoge"))
  end

  def test_q_decode_space()
    assert_equal("a b", MailParser::RFC2047.q_decode("a_b"))
  end

  def test_q_decode_utf8()
    assert_equal("とみた", MailParser::RFC2047.q_decode("=E3=81=A8=E3=81=BF=E3=81=9F"))
  end

  def test_q_decode_utf8_ascii()
    assert_equal("とaみbた", MailParser::RFC2047.q_decode("=E3=81=A8a=E3=81=BFb=E3=81=9F"))
  end

  def test_q_decode_end_equal()
    assert_equal("abc", MailParser::RFC2047.q_decode("abc="))
  end

  def test_b_decode_ascii()
    assert_equal("hoge", MailParser::RFC2047.b_decode("aG9nZQ=="))
  end

  def test_b_decode_utf8()
    assert_equal("とみた", MailParser::RFC2047.b_decode("44Go44G/44Gf"))
  end

  def test_b_decode_invalid_space()
    assert_equal("とみた", MailParser::RFC2047.b_decode("44Go 44 G/4 4Gf"))
  end

  def test_split_decode_q_ascii()
    s = MailParser::RFC2047.split_decode("=?us-ascii?q?hoge?=")
    assert_equal(1, s.size)
    assert_equal("hoge", s[0])
    assert_equal("us-ascii", s[0].charset)
    assert_equal("=?us-ascii?q?hoge?=", s[0].raw)
  end

  def test_split_decode_q_ascii_upcase()
    s = MailParser::RFC2047.split_decode("=?US-ASCII?Q?hoge?=")
    assert_equal(1, s.size)
    assert_equal("hoge", s[0])
    assert_equal("us-ascii", s[0].charset)
    assert_equal("=?US-ASCII?Q?hoge?=", s[0].raw)
  end

  def test_decode_q_ascii()
    s = MailParser::RFC2047.decode("=?us-ascii?q?hoge?=")
    assert_equal("hoge", s)
  end

  def test_decode_q_b()
    s = MailParser::RFC2047.decode("=?us-ascii?q?hoge?= =?us-ascii?b?aG9nZQ==?=")
    assert_equal("hogehoge", s)
  end

  def test_decode_plain()
    s = MailParser::RFC2047.decode("abcdefg")
    assert_equal("abcdefg", s)
  end

  def test_decode_encode_plain()
    s = MailParser::RFC2047.decode("012345 =?us-ascii?q?hoge?= abcdefg")
    assert_equal("012345 hoge abcdefg", s)
  end

  def test_decode_encode_plain2()
    s = MailParser::RFC2047.decode("=?us-ascii?q?hoge?= abcdefg =?us-ascii?q?fuga?=")
    assert_equal("hoge abcdefg fuga", s)
  end

  def test_decode_unknown_charset()
    s = MailParser::RFC2047.decode("=?hoge?q?hoge?=")
    assert_equal("hoge", s)
  end

  def test_decode_unknown_charset2()
    s = MailParser::RFC2047.decode("=?hoge?q?hoge?=", "UTF-8")
    assert_equal("=?hoge?q?hoge?=", s)
  end

  def test_decode_unknown_charset3()
    s = MailParser::RFC2047.decode("abcdefg =?hoge?q?hoge?= =?us-ascii?q?fuga?=")
    assert_equal("abcdefg hogefuga", s)
  end

  def test_decode_unknown_charset4()
    s = MailParser::RFC2047.decode("abcdefg =?hoge?q?hoge?= =?us-ascii?q?fuga?=", "UTF-8")
    assert_equal("abcdefg =?hoge?q?hoge?= fuga", s)
  end

  def test_decode_sjis()
    s = MailParser::RFC2047.decode("=?sjis?b?h0A=?=", "UTF-8")
    assert_equal("\xe2\x91\xa0", s)
  end

  def test_decode_iso2022jp()
    s = MailParser::RFC2047.decode("=?iso-2022-jp?b?GyRCLSEbKEI=?=", "UTF-8")
    assert_equal("\xe2\x91\xa0", s)
  end

  def test_decode_charset_converter()
    proc = Proc.new{|f,t,s| s.gsub(/o/, "X")}
    s = MailParser::RFC2047.decode("=?us-ascii?q?hoge?=", "utf-8", proc)
    assert_equal("hXge", s)
  end

end
