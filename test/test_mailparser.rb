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
    assert_equal(nil, m.charset)
  end

  def test_content_type_none()
    msg = StringIO.new(<<EOS)

EOS
    m = MailParser::Message.new(msg)
    assert_equal("text", m.type)
    assert_equal("plain", m.subtype)
    assert_equal(nil, m.charset)
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

  def test_filename_mime_decode_nofilename()
    msg = StringIO.new(<<EOS)
Content-Type: text/plain
EOS
    m = MailParser::Message.new(msg, :decode_mime_filename=>true)
    assert_nil m.filename
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

  def test_extract_message_type()
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: text/plain

body1

--xxxx
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain

body2
--xxxx--
EOS
    m = MailParser::Message.new(msg, :extract_message_type=>true)
    assert_equal("<from1@example.com>", m.from.to_s)
    assert_equal(2, m.part.size)
    assert_equal("text", m.part[0].type)
    assert_equal("body1\n", m.part[0].body)
    assert_equal("message", m.part[1].type)
    assert_equal("<from2@example.com>", m.part[1].message.from.to_s)
    assert_equal("body2", m.part[1].message.body)
  end

  def test_extract_message_type_header_only
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: text/plain

body1

--xxxx
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain
--xxxx--
EOS
    m = MailParser::Message.new(msg, :extract_message_type=>true)
    assert_equal("<from1@example.com>", m.from.to_s)
    assert_equal(2, m.part.size)
    assert_equal("text", m.part[0].type)
    assert_equal("body1\n", m.part[0].body)
    assert_equal("message", m.part[1].type)
    assert_equal("<from2@example.com>", m.part[1].message.from.to_s)
    assert_equal("", m.part[1].message.body)
  end

  def test_extract_message_type_skip_body()
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: text/plain

body1

--xxxx
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain

body2
--xxxx--
EOS
    m = MailParser::Message.new(msg, :extract_message_type=>true, :skip_body=>true)
    assert_equal("<from1@example.com>", m.from.to_s)
    assert_equal(2, m.part.size)
    assert_equal("text", m.part[0].type)
    assert_equal("", m.part[0].body)
    assert_equal("message", m.part[1].type)
    assert_equal("<from2@example.com>", m.part[1].message.from.to_s)
    assert_equal("", m.part[1].message.body)
  end

  def test_extract_message_type_text_body_only()
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: text/plain

body1

--xxxx
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain

body2

--xxxx--
EOS
    m = MailParser::Message.new(msg, :extract_message_type=>true, :text_body_only=>true)
    assert_equal("<from1@example.com>", m.from.to_s)
    assert_equal(2, m.part.size)
    assert_equal("text", m.part[0].type)
    assert_equal("body1\n", m.part[0].body)
    assert_equal("message", m.part[1].type)
    assert_equal("<from2@example.com>", m.part[1].message.from.to_s)
    assert_equal("body2\n", m.part[1].message.body)
  end

  def test_extract_multipart_alternative_attach()
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: multipart/alternative;
	boundary="yyyy"

--yyyy
Content-Type: text/plain; charset=iso-2022-jp

hoge

--yyyy
Content-Type: text/html; charset=iso-2022-jp

fuga html

--yyyy--

--xxxx
Content-Type: application/octet-stream; name="attach.txt"
Content-Disposition: attachment; filename="attach.txt"

attached file
--xxxx--
EOS
    m = MailParser::Message.new(msg)
    assert_equal(2, m.part.size)
    assert_equal(2, m.part[0].part.size)
    assert_equal("hoge\n", m.part[0].part[0].body)
    assert_equal("fuga html\n", m.part[0].part[1].body)
    assert_equal("attached file", m.part[1].body)
  end

  def test_extract_no_boundary()
    msg = StringIO.new(<<EOS)
From: from@example.com
Content-Type: multipart/mixed; boundary="xxx"

hoge
hoge
EOS
    m = MailParser::Message.new(msg)
    assert_equal("", m.body)
    assert_equal([], m.part)
  end

  def test_extract_no_end_boundary()
    msg = StringIO.new(<<EOS)
From: from@example.com
Content-Type: multipart/mixed; boundary="xxx"

--xxx
Content-Type: text/plain

hoge
hoge
EOS
    m = MailParser::Message.new(msg)
    assert_equal(1, m.part.size)
    assert_equal("hoge\nhoge\n", m.part[0].body)
  end

  def test_extract_no_end_boundary_nest()
    msg = StringIO.new(<<EOS)
From: from@example.com
Content-Type: multipart/mixed; boundary="xxx"

--xxx
Content-Type: multipart/mixed; boundary="yyy"

--yyy
Content-Type: text/plain

hoge
hoge

--xxx
Content-Type: text/plain

fuga

--xxx--
EOS
    m = MailParser::Message.new(msg)
    assert_equal(2, m.part.size)
    assert_equal(1, m.part[0].part.size)
    assert_equal("hoge\nhoge\n", m.part[0].part[0].body)
    assert_equal("fuga\n", m.part[1].body)
  end

  def test_parse_no_header_delimiter()
    msg = StringIO.new <<EOS
Subject: hoge
hogehoge
EOS
    m = MailParser::Message.new msg
    assert_equal "hoge", m.subject
    assert_equal "hogehoge\n", m.body
  end

  def test_parse_header_only_part()
    msg = StringIO.new <<EOS
Content-Type: multipart/mixed; boundary=abcdefg

--abcdefg
Content-Type: text/plain
--abcdefg
Content-Type: text/plain

hoge

--abcdefg--
EOS
    m = MailParser::Message.new msg
    assert_equal 2, m.part.size
    assert_equal "", m.part[0].body
    assert_equal "hoge\n", m.part[1].body
  end

  def test_parse_header_only_part2()
    msg = StringIO.new <<EOS
Content-Type: multipart/mixed; boundary=abcdefg

--abcdefg
Content-Type: multipart/mixed; boundary=xyz
--abcdefg
Content-Type: text/plain

hoge

--abcdefg--
EOS
    m = MailParser::Message.new msg
    assert_equal 2, m.part.size
    assert_equal "", m.part[0].body
    assert_equal "hoge\n", m.part[1].body
  end

  def test_raw_single_part
    msg = StringIO.new(<<EOS)
From: from@example.com
Content-Type: text/plain

hogehoge

fugafuga
EOS
    m = MailParser::Message.new msg, :keep_raw=>true
    assert_equal msg.string, m.raw
  end

  def test_raw_multi_part_nest
    msg = StringIO.new(<<EOS)
From: from@example.com
Content-Type: multipart/mixed; boundary="xxx"

--xxx
Content-Type: multipart/mixed; boundary="yyy"

--yyy
Content-Type: text/plain

hoge
hoge
--yyy
Content-Type: text/plain

hoge
hoge
--yyy--

--xxx
Content-Type: text/plain

fuga
--xxx--
EOS
    m = MailParser::Message.new msg, :keep_raw=>true
    assert_equal msg.string, m.raw
    assert_equal <<EOS, m.part[0].part[0].raw
Content-Type: text/plain

hoge
hoge
EOS
    assert_equal <<EOS, m.part[1].raw
Content-Type: text/plain

fuga
EOS
  end

  def test_raw_message_part
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: text/plain

body1

--xxxx
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain

body2
--xxxx--
EOS
    m = MailParser::Message.new msg, :keep_raw=>true
    assert_equal msg.string, m.raw
    assert_equal <<EOS, m.part[0].raw
Content-Type: text/plain

body1

EOS
    assert_equal <<EOS, m.part[1].raw
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain

body2
EOS
  end

  def test_raw_message_part_header_only
    msg = StringIO.new(<<EOS)
From: from1@example.com
Content-Type: multipart/mixed; boundary="xxxx"

--xxxx
Content-Type: text/plain

body1

--xxxx
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain
--xxxx--
EOS
    m = MailParser::Message.new msg, :keep_raw=>true
    assert_equal msg.string, m.raw
    assert_equal <<EOS, m.part[0].raw
Content-Type: text/plain

body1

EOS
    assert_equal <<EOS, m.part[1].raw
Content-Type: message/rfc822

From: from2@example.com
Content-Type: text/plain
EOS
  end

  def test_raw_with_continuous_header
    msg = StringIO.new(<<EOS)
From: from1@example.com
Subject: hogehoge
 fugafuga

body1
EOS
    m = MailParser::Message.new msg, :keep_raw=>true
    assert_equal <<EOS, m.raw
From: from1@example.com
Subject: hogehoge
 fugafuga

body1
EOS
  end

end

class TC_DelimIO < Test::Unit::TestCase
  include MailParser
  def setup()
  end
  def teardown()
  end

  def test_gets
    s = StringIO.new <<EOS
aaaa
bbbb
cccc
dddd
EOS
    dio = Message::DelimIO.new(Message::DelimIO.new(s), ["cccc"])
    assert_equal "aaaa\n", dio.gets
    assert_equal "bbbb\n", dio.gets
    assert_equal nil, dio.gets
    assert_equal true, dio.eof?
    dio.ungets
    assert_equal false, dio.eof?
    assert_equal "bbbb\n", dio.gets
    assert_equal nil, dio.gets
    assert_equal true, dio.eof?
  end

  def test_each_line
    s = StringIO.new <<EOS
aaaa
bbbb
cccc
dddd
EOS
    dio = Message::DelimIO.new(Message::DelimIO.new(s))
    ret = []
    dio.each_line do |line|
      ret << line
    end
    assert_equal ["aaaa\n","bbbb\n","cccc\n","dddd\n"], ret
    assert_equal true, dio.eof?
  end

  def test_each_line_delim
    s = StringIO.new <<EOS
aaaa
bbbb
cccc
dddd
EOS
    dio = Message::DelimIO.new(Message::DelimIO.new(s), ["cccc"])
    ret = []
    dio.each_line do |line|
      ret << line
    end
    assert_equal ["aaaa\n","bbbb\n"], ret
    assert_equal true, dio.eof?
  end

  def test_ungets
    s = StringIO.new <<EOS
aaaa
bbbb
cccc
dddd
EOS
    dio = Message::DelimIO.new(Message::DelimIO.new(s), ["cccc"])
    ret = []
    dio.each_line do |line|
      ret << line
    end
    assert_equal ["aaaa\n","bbbb\n"], ret
    assert_equal true, dio.eof?
    dio.ungets
    assert_equal false, dio.eof?
    assert_equal "bbbb\n", dio.gets
  end

end
