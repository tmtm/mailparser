#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/rfc2231"
require "test/unit"

class TC_RFC2231 < Test::Unit::TestCase
  def test_parse_param()
    params = {
      "hoge" => "fuga",
      "foo"  => "bar",
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("fuga", h["hoge"])
    assert_equal(nil, h["hoge"].charset)
    assert_equal(nil, h["hoge"].language)
    assert_equal("bar", h["foo"])
    assert_equal(nil, h["foo"].charset)
    assert_equal(nil, h["foo"].language)
  end

  def test_parse_param2()
    params = {
      "hoge*0" => "fuga",
      "hoge*1" => "bar",
      "foo"  => "bar",
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("fugabar", h["hoge"])
    assert_equal(nil, h["hoge"].charset)
    assert_equal(nil, h["hoge"].language)
    assert_equal("bar", h["foo"])
    assert_equal(nil, h["foo"].charset)
    assert_equal(nil, h["foo"].language)
  end

  def test_parse_param3()
    params = {
      "hoge*0*" => "''fuga",
      "hoge*1"  => "bar",
      "foo"  => "bar",
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("fugabar", h["hoge"])
    assert_equal("", h["hoge"].charset)
    assert_equal("", h["hoge"].language)
    assert_equal("bar", h["foo"])
    assert_equal(nil, h["foo"].charset)
    assert_equal(nil, h["foo"].language)
  end

  def test_parse_param4()
    params = {
      "hoge*0*" => "euc-jp'ja'fuga",
      "hoge*1"  => "bar",
      "foo"  => "bar",
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("fugabar", h["hoge"])
    assert_equal("euc-jp", h["hoge"].charset)
    assert_equal("ja", h["hoge"].language)
    assert_equal("bar", h["foo"])
    assert_equal(nil, h["foo"].charset)
    assert_equal(nil, h["foo"].language)
  end

  def test_parse_param5()
    params = {
      "hoge*0*" => "''%30%31%32%33",
      "hoge*1"  => "%34%35%36",
      "foo"  => "bar",
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("0123%34%35%36", h["hoge"])
    assert_equal("", h["hoge"].charset)
    assert_equal("", h["hoge"].language)
    assert_equal("bar", h["foo"])
    assert_equal(nil, h["foo"].charset)
    assert_equal(nil, h["foo"].language)
  end

  def test_parse_param6()
    params = {
      "hoge*" => "''fuga",
      "foo"  => "bar",
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("fuga", h["hoge"])
    assert_equal("", h["hoge"].charset)
    assert_equal("", h["hoge"].language)
    assert_equal("bar", h["foo"])
    assert_equal(nil, h["foo"].charset)
    assert_equal(nil, h["foo"].language)
  end

  def test_parse_param7()
    params = {
      "hoge*" => "fuga",
    }
    assert_raises(MailParser::ParseError){MailParser::RFC2231.parse_param(params)}
  end

  def test_parse_param8()
    params = {
      "hoge*0*" => "fuga",
    }
    assert_raises(MailParser::ParseError){MailParser::RFC2231.parse_param(params)}
  end

  def test_rfc_example()
    params = {
      "URL*0" => "ftp://",
      "URL*1" => "cs.utk.edu.pub/moore/bulk-mailer/buik-mailer.tar"
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("ftp://cs.utk.edu.pub/moore/bulk-mailer/buik-mailer.tar", h["URL"])
    assert_equal(nil, h["URL"].charset)
    assert_equal(nil, h["URL"].language)
  end

  def test_rfc_example2()
    params = {
      "title*" => "us-ascii'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A"
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("This is ***fun***", h["title"])
    assert_equal("us-ascii", h["title"].charset)
    assert_equal("en-us", h["title"].language)
  end

  def test_rfc_example3()
    params = {
      "title*0*" => "us-ascii'en'This%20is%20even%20more%20",
      "title*1*" => "%2A%2A%2Afun%2A%2A%2A%20",
      "title*2"  => "isn't it!"
    }
    h = MailParser::RFC2231.parse_param(params)
    assert_equal("This is even more ***fun*** isn't it!", h["title"])
    assert_equal("us-ascii", h["title"].charset)
    assert_equal("en", h["title"].language)
  end

end
