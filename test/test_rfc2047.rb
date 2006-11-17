#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
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

  def test_decode_q_ascii()
    s = MailParser::RFC2047.decode("=?us_ascii?q?hoge?=")
    assert_equal(1, s.size)
    assert_equal("us_ascii", s[0].charset)
    assert_equal("hoge", s[0])
  end

  def test_decode_q_ascii_upcase()
    s = MailParser::RFC2047.decode("=?US_ASCII?Q?hoge?=")
    assert_equal(1, s.size)
    assert_equal("us_ascii", s[0].charset)
    assert_equal("hoge", s[0])
  end
end
