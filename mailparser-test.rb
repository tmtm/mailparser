#!/usr/local/bin/ruby
# $Id: mailparser-test.rb,v 1.13 2006/03/29 23:29:26 tommy Exp $

require "test/unit"
require "./mailparser"
include MailParser

class TC_MailParser < Test::Unit::TestCase
  def setup()
    MailParser.output_charset = "euc-jp"
    MailParser.text_body_only = false
  end
  def test_get_mail_address()
    assert_equal(["foo@example.jp"], get_mail_address("foo@example.jp"))
  end
  def test_get_mail_address2()
    assert_equal(["foo@example.jp", "bar@example.com"], get_mail_address("foo@example.jp, bar@example.com"))
  end
  def test_get_mail_address_with_phrase()
    assert_equal(["foo@example.jp"], get_mail_address("phrase <foo@example.jp>"))
  end
  def test_get_mail_address_with_phrase2()
    assert_equal(["foo@example.jp"], get_mail_address("\"foo bar\" <foo@example.jp>"))
  end
  def test_get_mail_address_with_comment()
    assert_equal(["foo@example.jp"], get_mail_address("foo@example.jp (comment)"))
  end
  def test_get_mail_address_with_comment_nest()
    assert_equal(["foo@example.jp"], get_mail_address("foo@example.jp (nested (comment))"))
  end
  def test_get_mail_address_invalid_dquot()
    assert_equal(["foo@example.jp"], get_mail_address("\"aaa\"bb\"cc <foo@example.jp>"))
  end
  def test_get_mail_address_complex()
    assert_equal(["foo@example.jp", "bar@example.com"], get_mail_address("\"foo\" <foo@example.jp>, bar@example.com (comment)"))
  end
  def test_get_mail_address_invalid_parenthes()
    str = (["\"aaaa(aaaaa(\\(aaaa(\\)\" <hoge@example.com>"]*50).join(",")
    assert_equal(["hoge@example.com"]*50, get_mail_address(str))
  end
  def test_get_mail_address_parenthes_in_phrace()
    assert_equal(["foo@example.com", "bar@example.com"], get_mail_address("\"hoge(xxx\" <foo@example.com>, \")\" <bar@example.com>" ))
  end
  def test_get_mail_address_angle_in_phrace()
    assert_equal(["bar@example.com"], get_mail_address("\"<hoge>\" <bar@example.com>" ))
  end
  def test_parse_content_type()
    h = parse_content_type("text/plain; charset=euc-jp")
    assert_equal("text", h[:type])
    assert_equal("plain", h[:subtype])
    assert_equal("euc-jp", h[:parameter]["charset"])
  end
  def test_parse_content_type2()
    h = parse_content_type("multipart/mixed; boundary=\"boundary-string\"")
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("boundary-string", h[:parameter]["boundary"])
  end
  def test_parse_content_type_caps()
    h = parse_content_type("Text/HTML; CharSet=Euc-JP")
    assert_equal("text", h[:type])
    assert_equal("html", h[:subtype])
    assert_equal("Euc-JP", h[:parameter]["charset"])
  end
  def test_parse_content_type_rfc2231()
    h = parse_content_type("message/external-body; access-type=URL; URL*0=\"ftp://\"; URL*1=\"cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar\"")
    assert_equal("message", h[:type])
    assert_equal("external-body", h[:subtype])
    assert_equal("URL", h[:parameter]["access-type"])
    assert_equal("ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar", h[:parameter]["url"])
  end
  def test_parse_content_type_rfc2231_ext()
    h = parse_content_type("application/x-stuff; title*=us-ascii'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A")
    assert_equal("application", h[:type])
    assert_equal("x-stuff", h[:subtype])
    assert_equal("This is ***fun***", h[:parameter]["title"])
  end
  def test_parse_content_type_rfc2231_ext_multi()
    h = parse_content_type("application/x-stuff; title*0*=us-ascii'en-us'This%20is%20even%20more%20; title*1*=%2A%2A%2Afun%2A%2A%2A%20; title*2*=\"isn't it!\"")
    assert_equal("application", h[:type])
    assert_equal("x-stuff", h[:subtype])
    assert_equal("This is even more ***fun*** isn't it!", h[:parameter]["title"])
  end
  def test_parse_content_type_rfc2231_ext_nocharset()
    h = parse_content_type("application/x-stuff; title*='en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A")
    assert_equal("application", h[:type])
    assert_equal("x-stuff", h[:subtype])
    assert_equal("This is ***fun***", h[:parameter]["title"])
  end
  def test_parse_content_type_rfc2231_ext_nolang()
    h = parse_content_type("application/x-stuff; title*=us-ascii''This%20is%20%2A%2A%2Afun%2A%2A%2A")
    assert_equal("application", h[:type])
    assert_equal("x-stuff", h[:subtype])
    assert_equal("This is ***fun***", h[:parameter]["title"])
  end
  def test_parse_content_type_rfc2231_ext_nocharset_nolang()
    h = parse_content_type("application/x-stuff; title*=''This%20is%20%2A%2A%2Afun%2A%2A%2A")
    assert_equal("application", h[:type])
    assert_equal("x-stuff", h[:subtype])
    assert_equal("This is ***fun***", h[:parameter]["title"])
  end
  def test_parse_content_type_rfc2231_ext_sjis()
    h = parse_content_type("application/octet-stream; name*=shift_jis''%83%65%83%58%83%67")
    assert_equal("application", h[:type])
    assert_equal("octet-stream", h[:subtype])
    assert_equal("テスト", h[:parameter]["name"])
  end
  def test_mime_header_decode_plain()
    assert_equal("test", mime_header_decode("test"))
  end
  def test_mime_header_decode_jis()
    assert_equal("テスト", mime_header_decode("=?iso-2022-jp?b?GyRCJUYlOSVIGyhC?="))
  end
  def test_mime_header_decode_sjis()
    assert_equal("テスト", mime_header_decode("=?shift_jis?b?g2WDWINn?="))
  end
  def test_mime_header_decode_euc()
    assert_equal("テスト", mime_header_decode("=?euc-jp?b?pcaluaXI?="))
  end
  def test_mime_header_decode_utf8()
    assert_equal("テスト", mime_header_decode("=?utf-8?b?44OG44K544OI?="))
  end
  def test_mime_header_decode_ascii()
    assert_equal("test", mime_header_decode("=?us-ascii?b?dGVzdA==?="))
  end
  def test_mime_header_decode_unknown()
    assert_equal("=?unknown?b?dGVzdA==?=", mime_header_decode("=?unknown?b?dGVzdA==?="))
  end
  def test_mime_header_decode_q()
    assert_equal("test", mime_header_decode("=?us-ascii?q?test?="))
  end
  def test_mime_header_decode_q_multi()
    assert_equal("testtest", mime_header_decode("=?us-ascii?q?test?= =?us-ascii?q?test?="))
  end
  def test_mime_header_decode_q_euc()
    assert_equal("テスト", mime_header_decode("=?euc-jp?q?=A5=C6=A5=B9=A5=C8?="))
  end
  def test_mime_header_decode_e2u()
    MailParser.output_charset = "utf-8"
    assert_equal("\xE3\x83\x86\xE3\x82\xB9\xE3\x83\x88", mime_header_decode("=?euc-jp?q?=A5=C6=A5=B9=A5=C8?="))
  end
  def test_mime_header_decode_s2u()
    MailParser.output_charset = "utf-8"
    assert_equal("\xE3\x83\x86\xE3\x82\xB9\xE3\x83\x88", mime_header_decode("=?shift_jis?q?=83=65=83=58=83=67?="))
  end
  def test_mime_header_decode_noconv()
    MailParser.output_charset = nil
    assert_equal("\x83\x65\x83\x58\x83\x67", mime_header_decode("=?shift_jis?q?=83=65=83=58=83=67?="))
  end
  def test_trunc_comment()
    assert_equal("abcdefg", trunc_comment("abcdefg"))
  end
  def test_trunc_comment_2()
    assert_equal("abcdefg", trunc_comment("abc(comment)defg"))
  end
  def test_trunc_comment_3()
    assert_equal("abcdefg", trunc_comment("abc(com(comment)ment)defg"))
  end
  def test_trunc_comment_4()
    assert_equal("\"abc(comment)def\" hoge", trunc_comment("\"abc(comment)def\" hoge"))
  end
  def test_trunc_comment_5()
    assert_equal("\"abc(com\" hoge", trunc_comment("\"abc(com\" hoge"))
  end
  def test_trunc_comment_6()
    assert_equal("\"abc(com\" hoge \"com)def\"", trunc_comment("\"abc(com\" hoge \"com)def\""))
  end
  def test_trunc_comment_invalid_parenthes()
    assert_equal("abc(def", trunc_comment("abc(def"))
  end
  def test_trunc_comment_invalid_parenthes2()
    assert_equal("abc(def(ghi)", trunc_comment("abc(def(ghi)"))
  end
  def test_trunc_comment_invalid_parenthes3()
    assert_equal("abc(ghi", trunc_comment("abc(def)(ghi"))
  end
  def test_trunc_comment_invalid_parenthes4()
    assert_equal("abc(", trunc_comment("abc("))
  end
  def test_trunc_comment_last_backslash()
    assert_equal("abc\\", trunc_comment("abc\\"))
  end
  def test_trunc_comment_sub()
    assert_equal("def", trunc_comment_sub("abc)def"))
  end
  def test_trunc_comment_sub2()
    assert_equal("", trunc_comment_sub("abc)"))
  end
  def test_trunc_comment_sub3()
    assert_equal(nil, trunc_comment_sub("abc"))
  end
  def test_trunc_comment_sub4()
    assert_equal("jkl", trunc_comment_sub("abc(def)ghi)jkl"))
  end
  def test_trunc_comment_sub5()
    assert_equal("ghi", trunc_comment_sub("abc\\)def)ghi"))
  end
  def test_trunc_comment_sub6()
    assert_equal("ghi", trunc_comment_sub("abc\\(def)ghi"))
  end
  def test_split_address()
    assert_equal(["a@a.a"], split_address("a@a.a"))
  end
  def test_split_address2()
    assert_equal(["a@a.a","b@b.b"], split_address("a@a.a, b@b.b"))
  end
  def test_split_address3()
    assert_equal(["\"a@a.a,\" b@b.b"], split_address("\"a@a.a,\" b@b.b"))
  end
  def test_split_address4()
    assert_equal(["\"a@a.a","b@b.b"], split_address("\"a@a.a, b@b.b"))
  end
  def test_get_date()
    assert_equal(Time.mktime(2005,1,4,23,10,20), get_date("Tue, 4 Jan 2005 23:10:20 +0900"))
  end
  def test_get_date_far_future()
    assert_equal(nil, get_date("Tue, 4 Jan 2090 23:10:20 +0900"))
  end
  def test_get_date_deep_past()
    assert_equal(nil, get_date("Tue, 4 Jan 1900 23:10:20 +0900"))
  end
  def test_get_date_invalid()
    assert_equal(nil, get_date("XXX, 99 Jan 205 23:10:20 +0900"))
  end
  def test_parse_message()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>
To: Foo Bar <foo.bar@example.com>
Subject: =?iso-2022-jp?b?GyRCNEE7ehsoQg==?=
Content-Type: text/plain; charset=euc-jp
Date: Tue, 4 Jan 2005 14:54:22 +0900

日本語本文
EOS
    assert_equal(["tommy@tmtm.org"], h[:from])
    assert_equal(["foo.bar@example.com"], h[:to])
    assert_equal("漢字", h[:subject])
    assert_equal(["TOMITA Masahiro <tommy@tmtm.org>"], h[:header]["from"])
    assert_equal(["漢字"], h[:header]["subject"])
    assert_equal("text", h[:type])
    assert_equal("plain", h[:subtype])
    assert_equal("euc-jp", h[:charset])
    assert_equal("日本語本文\n", h[:body])
    assert_equal(<<EOS, h[:rawheader])
From: TOMITA Masahiro <tommy@tmtm.org>
To: Foo Bar <foo.bar@example.com>
Subject: =?iso-2022-jp?b?GyRCNEE7ehsoQg==?=
Content-Type: text/plain; charset=euc-jp
Date: Tue, 4 Jan 2005 14:54:22 +0900
EOS
  end
  def test_parse_message_with_attachment()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: text/plain

This is body.
--hogehogehoge
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(2, h[:parts].size)
    assert_equal("text", h[:parts][0][:type])
    assert_equal("plain", h[:parts][0][:subtype])
    assert_equal("This is body.\n", h[:parts][0][:body])
    assert_equal("application", h[:parts][1][:type])
    assert_equal("octet-stream", h[:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][1][:encoding])
    assert_equal("This is attachment file.\n", h[:parts][1][:body])
  end
  def test_parse_message_with_attachment_text_only()
    require "stringio"
    MailParser.text_body_only = true
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: text/plain

This is body.
--hogehogehoge
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(2, h[:parts].size)
    assert_equal("text", h[:parts][0][:type])
    assert_equal("plain", h[:parts][0][:subtype])
    assert_equal("This is body.\n", h[:parts][0][:body])
    assert_equal("application", h[:parts][1][:type])
    assert_equal("octet-stream", h[:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][1][:encoding])
    assert_nil(h[:parts][1][:body])
  end
  def test_parse_message_with_message_type()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: message/rfc822

Content-Type: multipart/mixed; boundary="fugafugafuga"

preamble
--fugafugafuga
Content-Type: text/plain

This is body.
--fugafugafuga
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--fugafugafuga--
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(1, h[:parts].size)
    assert_equal("message", h[:parts][0][:type])
    assert_equal("rfc822", h[:parts][0][:subtype])
    assert_nil(h[:parts][0][:message][:body])
    assert_equal(2, h[:parts][0][:message][:parts].size)
    assert_equal("This is body.\n", h[:parts][0][:message][:parts][0][:body])
    assert_equal("application", h[:parts][0][:message][:parts][1][:type])
    assert_equal("octet-stream", h[:parts][0][:message][:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][0][:message][:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][0][:message][:parts][1][:encoding])
    assert_equal("This is attachment file.\n", h[:parts][0][:message][:parts][1][:body])
  end
  def test_parse_message_with_multipart_in_multipart()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: multipart/mixed; boundary="fugafugafuga"

preamble
--fugafugafuga
Content-Type: text/plain

This is body.
--fugafugafuga
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--fugafugafuga--
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(1, h[:parts].size)
    assert_equal("multipart", h[:parts][0][:type])
    assert_equal("mixed", h[:parts][0][:subtype])
    assert_equal(2, h[:parts][0][:parts].size)
    assert_equal("This is body.\n", h[:parts][0][:parts][0][:body])
    assert_equal("application", h[:parts][0][:parts][1][:type])
    assert_equal("octet-stream", h[:parts][0][:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][0][:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][0][:parts][1][:encoding])
    assert_equal("This is attachment file.\n", h[:parts][0][:parts][1][:body])
  end
  def test_parse_message_with_multipart_of_multipart_and_singlepart()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: multipart/mixed; boundary="fugafugafuga"

preamble
--fugafugafuga
Content-Type: text/plain

This is body.
--fugafugafuga
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--fugafugafuga--
--hogehogehoge
Content-Type: text/plain

This is attachment body.
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(2, h[:parts].size)
    assert_equal("multipart", h[:parts][0][:type])
    assert_equal("mixed", h[:parts][0][:subtype])
    assert_equal(2, h[:parts][0][:parts].size)
    assert_equal("This is body.\n", h[:parts][0][:parts][0][:body])
    assert_equal("application", h[:parts][0][:parts][1][:type])
    assert_equal("octet-stream", h[:parts][0][:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][0][:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][0][:parts][1][:encoding])
    assert_equal("This is attachment file.\n", h[:parts][0][:parts][1][:body])
    assert_equal("text", h[:parts][1][:type])
    assert_equal("plain", h[:parts][1][:subtype])
    assert_equal("This is attachment body.\n", h[:parts][1][:body])
  end
  def test_parse_message_with_multipart_of_multipart_and_singlepart2()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: multipart/mixed; boundary="fugafugafuga"

preamble
--fugafugafuga
Content-Type: text/plain

This is body.
--fugafugafuga
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--fugafugafuga--
--hogehogehoge
Content-Type: text/plain

This is attachment body.
--hogehogehoge
Content-Type: text/plain

This is attachment body2.
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(3, h[:parts].size)
    assert_equal("multipart", h[:parts][0][:type])
    assert_equal("mixed", h[:parts][0][:subtype])
    assert_equal(2, h[:parts][0][:parts].size)
    assert_equal("This is body.\n", h[:parts][0][:parts][0][:body])
    assert_equal("application", h[:parts][0][:parts][1][:type])
    assert_equal("octet-stream", h[:parts][0][:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][0][:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][0][:parts][1][:encoding])
    assert_equal("This is attachment file.\n", h[:parts][0][:parts][1][:body])
    assert_equal("text", h[:parts][1][:type])
    assert_equal("plain", h[:parts][1][:subtype])
    assert_equal("This is attachment body.\n", h[:parts][1][:body])
    assert_equal("text", h[:parts][2][:type])
    assert_equal("plain", h[:parts][2][:subtype])
    assert_equal("This is attachment body2.\n", h[:parts][2][:body])
  end
  def test_parse_message_with_multipart_of_multipart_and_singlepart3()
    require "stringio"
    h = parse_message StringIO.new(<<EOS)
Content-Type: multipart/mixed; boundary="hogehogehoge"

preamble
--hogehogehoge
Content-Type: multipart/mixed; boundary="fugafugafuga"

preamble
--fugafugafuga
Content-Type: text/plain

This is body.
--fugafugafuga
Content-Type: application/octet-stream
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment; filename="file1.bin"

This is attachment file.
--fugafugafuga--
--hogehogehoge
Content-Type: multipart/mixed; boundary="heroherohero"

preamble
--heroherohero
Content-Type: text/plain

This is attachment body.
--heroherohero
Content-Type: text/plain

This is attachment body2.
--heroherohero--
--hogehogehoge--
EOS
    assert_equal("multipart", h[:type])
    assert_equal("mixed", h[:subtype])
    assert_equal("hogehogehoge", h[:boundary])
    assert_nil(h[:body])
    assert_equal(2, h[:parts].size)
    assert_equal("multipart", h[:parts][0][:type])
    assert_equal("mixed", h[:parts][0][:subtype])
    assert_equal(2, h[:parts][0][:parts].size)
    assert_equal("This is body.\n", h[:parts][0][:parts][0][:body])
    assert_equal("application", h[:parts][0][:parts][1][:type])
    assert_equal("octet-stream", h[:parts][0][:parts][1][:subtype])
    assert_equal("file1.bin", h[:parts][0][:parts][1][:filename])
    assert_equal("quoted-printable", h[:parts][0][:parts][1][:encoding])
    assert_equal("This is attachment file.\n", h[:parts][0][:parts][1][:body])
    assert_equal("multipart", h[:parts][1][:type])
    assert_equal("mixed", h[:parts][1][:subtype])
    assert_equal(2, h[:parts][1][:parts].size)
    assert_equal("text", h[:parts][1][:parts][0][:type])
    assert_equal("plain", h[:parts][1][:parts][0][:subtype])
    assert_equal("This is attachment body.\n", h[:parts][1][:parts][0][:body])
    assert_equal("text", h[:parts][1][:parts][1][:type])
    assert_equal("plain", h[:parts][1][:parts][1][:subtype])
    assert_equal("This is attachment body2.\n", h[:parts][1][:parts][1][:body])
  end
end
