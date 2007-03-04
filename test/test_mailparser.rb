# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser"
require "test/unit"

class TC_Message < Test::Unit::TestCase
  def setup()
  end
  def teardown()
  end

  def test_from()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_equal("tommy", m.from.addr_spec.local_part)
    assert_equal("tmtm.org", m.from.addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.from.display_name)
    assert_equal([], m.from.comments)
  end

  def test_from_mime()
    msg = StringIO.new(<<EOS)
From: =?us-ascii?q?TOMITA_Masahiro?= <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_equal("tommy", m.from.addr_spec.local_part)
    assert_equal("tmtm.org", m.from.addr_spec.domain)
    assert_equal("=?us-ascii?q?TOMITA_Masahiro?=", m.from.display_name)
    assert_equal([], m.from.comments)
  end

  def test_from_mime_decode()
    msg = StringIO.new(<<EOS)
From: =?us-ascii?q?TOMITA_Masahiro?= <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg, :decode_mime_header=>true)
    assert_equal("tommy", m.from.addr_spec.local_part)
    assert_equal("tmtm.org", m.from.addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.from.display_name)
    assert_equal([], m.from.comments)
  end

  def test_from_none()
    msg = StringIO.new(<<EOS)
Sender: TOMITA Masahiro <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_nil(m.from)
  end

  def test_from_multi()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>, hoge@example.com

EOS
    m = MailParser::Message.new(msg)
    assert_equal("tommy", m.from.addr_spec.local_part)
    assert_equal("tmtm.org", m.from.addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.from.display_name)
    assert_equal([], m.from.comments)
  end

  def test_from_comment()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org> (hoge hoge)

EOS
    m = MailParser::Message.new(msg)
    assert_equal("tommy", m.from.addr_spec.local_part)
    assert_equal("tmtm.org", m.from.addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.from.display_name)
    assert_equal(["(hoge hoge)"], m.from.comments)
  end

  def test_to()
    msg = StringIO.new(<<EOS)
To: TOMITA Masahiro <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_equal(1, m.to.size)
    assert_equal("tommy", m.to[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.to[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.to[0].display_name)
    assert_equal([], m.to[0].comments)
  end

  def test_to_none()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_equal([], m.to)
  end

  def test_to_multi()
    msg = StringIO.new(<<EOS)
To: TOMITA Masahiro <tommy@tmtm.org>, hoge@example.com

EOS
    m = MailParser::Message.new(msg)
    assert_equal(2, m.to.size)
    assert_equal("tommy", m.to[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.to[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.to[0].display_name)
    assert_equal([], m.to[0].comments)
    assert_equal("hoge", m.to[1].addr_spec.local_part)
    assert_equal("example.com", m.to[1].addr_spec.domain)
    assert_equal("", m.to[1].display_name)
    assert_equal([], m.to[1].comments)
  end

  def test_to_multi_header()
    msg = StringIO.new(<<EOS)
To: TOMITA Masahiro <tommy@tmtm.org>, hoge@example.com
To: fuga@example.jp

EOS
    m = MailParser::Message.new(msg)
    assert_equal(3, m.to.size)
    assert_equal("tommy", m.to[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.to[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.to[0].display_name)
    assert_equal([], m.to[0].comments)
    assert_equal("hoge", m.to[1].addr_spec.local_part)
    assert_equal("example.com", m.to[1].addr_spec.domain)
    assert_equal("", m.to[1].display_name)
    assert_equal([], m.to[1].comments)
    assert_equal("fuga", m.to[2].addr_spec.local_part)
    assert_equal("example.jp", m.to[2].addr_spec.domain)
    assert_equal("", m.to[2].display_name)
    assert_equal([], m.to[2].comments)
  end

  def test_to_comment()
    msg = StringIO.new(<<EOS)
To: TOMITA Masahiro <tommy@tmtm.org> (foo), hoge@example.com (bar)

EOS
    m = MailParser::Message.new(msg)
    assert_equal(2, m.to.size)
    assert_equal("tommy", m.to[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.to[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.to[0].display_name)
    assert_equal(["(foo)"], m.to[0].comments)
    assert_equal("hoge", m.to[1].addr_spec.local_part)
    assert_equal("example.com", m.to[1].addr_spec.domain)
    assert_equal("", m.to[1].display_name)
    assert_equal(["(bar)"], m.to[1].comments)
  end

  def test_cc()
    msg = StringIO.new(<<EOS)
Cc: TOMITA Masahiro <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_equal(1, m.cc.size)
    assert_equal("tommy", m.cc[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.cc[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.cc[0].display_name)
    assert_equal([], m.cc[0].comments)
  end

  def test_cc_none()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>

EOS
    m = MailParser::Message.new(msg)
    assert_equal([], m.cc)
  end

  def test_cc_multi()
    msg = StringIO.new(<<EOS)
Cc: TOMITA Masahiro <tommy@tmtm.org>, hoge@example.com

EOS
    m = MailParser::Message.new(msg)
    assert_equal(2, m.cc.size)
    assert_equal("tommy", m.cc[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.cc[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.cc[0].display_name)
    assert_equal([], m.cc[0].comments)
    assert_equal("hoge", m.cc[1].addr_spec.local_part)
    assert_equal("example.com", m.cc[1].addr_spec.domain)
    assert_equal("", m.cc[1].display_name)
    assert_equal([], m.cc[1].comments)
  end

  def test_cc_multi_header()
    msg = StringIO.new(<<EOS)
Cc: TOMITA Masahiro <tommy@tmtm.org>, hoge@example.com
Cc: fuga@example.jp

EOS
    m = MailParser::Message.new(msg)
    assert_equal(3, m.cc.size)
    assert_equal("tommy", m.cc[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.cc[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.cc[0].display_name)
    assert_equal([], m.cc[0].comments)
    assert_equal("hoge", m.cc[1].addr_spec.local_part)
    assert_equal("example.com", m.cc[1].addr_spec.domain)
    assert_equal("", m.cc[1].display_name)
    assert_equal([], m.cc[1].comments)
    assert_equal("fuga", m.cc[2].addr_spec.local_part)
    assert_equal("example.jp", m.cc[2].addr_spec.domain)
    assert_equal("", m.cc[2].display_name)
    assert_equal([], m.cc[2].comments)
  end

  def test_cc_comment()
    msg = StringIO.new(<<EOS)
Cc: TOMITA Masahiro <tommy@tmtm.org> (foo), hoge@example.com (bar)

EOS
    m = MailParser::Message.new(msg)
    assert_equal(2, m.cc.size)
    assert_equal("tommy", m.cc[0].addr_spec.local_part)
    assert_equal("tmtm.org", m.cc[0].addr_spec.domain)
    assert_equal("TOMITA Masahiro", m.cc[0].display_name)
    assert_equal(["(foo)"], m.cc[0].comments)
    assert_equal("hoge", m.cc[1].addr_spec.local_part)
    assert_equal("example.com", m.cc[1].addr_spec.domain)
    assert_equal("", m.cc[1].display_name)
    assert_equal(["(bar)"], m.cc[1].comments)
  end

  def test_subject()
    msg = StringIO.new(<<EOS)
Subject: This is a pen.

EOS
    m = MailParser::Message.new(msg)
    assert_equal("This is a pen.", m.subject)
  end

  def test_subject_none()
    msg = StringIO.new(<<EOS)
X-Subject: This is a pen.

EOS
    m = MailParser::Message.new(msg)
    assert_equal("", m.subject)
  end

  def test_subject_multi_line()
    msg = StringIO.new(<<EOS)
Subject: This is a pen.
  Is this a pen?

EOS
    m = MailParser::Message.new(msg)
    assert_equal("This is a pen. Is this a pen?", m.subject)
  end

  def test_subject_multi_header()
    msg = StringIO.new(<<EOS)
Subject: This is a pen.
Subject: Is this a pen?

EOS
    m = MailParser::Message.new(msg)
    assert_equal("This is a pen. Is this a pen?", m.subject)
  end

  def test_subject_mime()
    msg = StringIO.new(<<EOS)
Subject: =?us-ascii?q?This_is_a_pen.?=

EOS
    m = MailParser::Message.new(msg)
    assert_equal("=?us-ascii?q?This_is_a_pen.?=", m.subject)
  end

  def test_subject_mime_decode()
    msg = StringIO.new(<<EOS)
Subject: =?us-ascii?q?This_is_a_pen.?=

EOS
    m = MailParser::Message.new(msg, :decode_mime_header=>true)
    assert_equal("This is a pen.", m.subject)
  end

  def test_subject_mime_decode_charset()
    msg = StringIO.new(<<EOS)
Subject: =?iso-2022-jp?b?GyRCJCIkJCQmJCgkKhsoQg==?=

EOS
    m = MailParser::Message.new(msg, :decode_mime_header=>true, :output_charset=>"utf-8")
    assert_equal("あいうえお", m.subject)
  end

  def test_subject_mime_decode_unknown_charset()
    msg = StringIO.new(<<EOS)
Subject: =?xxx?b?GyRCJCIkJCQmJCgkKhsoQg==?=

EOS
    m = MailParser::Message.new(msg, :decode_mime_header=>true, :output_charset=>"utf-8")
    assert_equal("=?xxx?b?GyRCJCIkJCQmJCgkKhsoQg==?=", m.subject)
  end

  def test_content_type()
    msg = StringIO.new(<<EOS)
Content-Type: text/plain; charset=us-ascii

EOS
    m = MailParser::Message.new(msg)
    assert_equal("text", m.type)
    assert_equal("plain", m.subtype)
    assert_equal("us-ascii", m.charset)
  end

  def test_content_type_miss()
    msg = StringIO.new(<<EOS)
Content-Type: text

EOS
    m = MailParser::Message.new(msg)
    assert_equal("text", m.type)
    assert_equal("plain", m.subtype)
    assert_equal("us-ascii", m.charset)
  end

  def test_content_type_none()
    msg = StringIO.new(<<EOS)

EOS
    m = MailParser::Message.new(msg)
    assert_equal("text", m.type)
    assert_equal("plain", m.subtype)
    assert_equal("us-ascii", m.charset)
  end

  def test_body()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>
Content-Type: text/plain; charset=us-ascii

Test message.
EOS
    m = MailParser::Message.new(msg)
    assert_equal("Test message.\n", m.body)
  end

  def test_body_iso2022jp()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>
Content-Type: text/plain; charset=iso-2022-jp

\e\$B\$\"\$\$\$\&\$\(\$\*\e(B
EOS
    m = MailParser::Message.new(msg)
    assert_equal("\e\$B\$\"\$\$\$\&\$\(\$\*\e(B\n", m.body)
  end

  def test_body_iso2022jp_charset()
    msg = StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>
Content-Type: text/plain; charset=iso-2022-jp

\e\$B\$\"\$\$\$\&\$\(\$\*\e(B
EOS
    m = MailParser::Message.new(msg, :output_charset=>"utf8")
    assert_equal("あいうえお\n", m.body)
  end

  def test_filename()
    msg = StringIO.new(<<EOS)
Content-Type: text/plain; name="filename.txt"

EOS
    m = MailParser::Message.new(msg)
    assert_equal("filename.txt", m.filename)
  end

  def test_filename2()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename="filename.txt"

EOS
    m = MailParser::Message.new(msg)
    assert_equal("filename.txt", m.filename)
  end

  def test_filename3()
    msg = StringIO.new(<<EOS)
Content-Type: text/plain; name="ctype.txt"
Content-Disposition: attachment; filename="cdisp.txt"

EOS
    m = MailParser::Message.new(msg)
    assert_equal("cdisp.txt", m.filename)
  end

  def test_filename_rfc2231()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename*=us-ascii'en'filename.txt

EOS
    m = MailParser::Message.new(msg)
    assert_equal("filename.txt", m.filename)
  end

  def test_filename_rfc2231_charset()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename*=iso-2022-jp''%1B$B$%22$$$&$%28$%2A%1B%28B.txt

EOS
    m = MailParser::Message.new(msg, :output_charset=>"utf-8")
    assert_equal("あいうえお.txt", m.filename)
  end

  def test_filename_rfc2231_unknown_charset()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename*=xxxx''%1B$B$%22$$$&$%28$%2A%1B%28B.txt

EOS
    m = MailParser::Message.new(msg, :output_charset=>"utf-8")
    assert_equal("\e$B$\"$$$&$($*\e(B.txt", m.filename)
  end

  def test_filename_mime()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename="=?us-ascii?q?filename.txt?="

EOS
    m = MailParser::Message.new(msg)
    assert_equal("=?us-ascii?q?filename.txt?=", m.filename)
  end

  def test_filename_mime_decode()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename="=?us-ascii?q?filename.txt?="

EOS
    m = MailParser::Message.new(msg, :decode_mime_filename=>true)
    assert_equal("filename.txt", m.filename)
  end

  def test_filename_mime_charset()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename="=?iso-2022-jp?q?=1B$B$=22$$$&$=28$=2A=1B=28B.txt?="

EOS
    m = MailParser::Message.new(msg, :decode_mime_filename=>true, :output_charset=>"utf-8")
    assert_equal("あいうえお.txt", m.filename)
  end

  def test_filename_mime_unknown_charset()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename="=?xxx?q?=1B$B$=22$$$&$=28$=2A=1B=28B.txt?="

EOS
    m = MailParser::Message.new(msg, :decode_mime_filename=>true, :output_charset=>"utf-8")
    assert_equal("=?xxx?q?=1B$B$=22$$$&$=28$=2A=1B=28B.txt?=", m.filename)
  end

  def test_filename_invalid_crlf()
    msg = StringIO.new(<<EOS)
Content-Disposition: attachment; filename="aaaa
    bbb"

EOS
    m = MailParser::Message.new(msg)
    assert_equal("aaaa bbb", m.filename)
  end

end
