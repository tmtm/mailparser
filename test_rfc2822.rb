#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "rfc2822"

unless ARGV.empty?
  ARGV.each do |fname|
    File.open(fname) do |f|
      header = []
      f.each do |line|
        break if line.chomp.empty?
        if line =~ /^\s/ then
          header[-1] << line
        else
          header << line
        end
      end
      header.each do |h|
        begin
          RFC2822.parse(*h.split(/\s*:\s*/, 2))
        rescue RFC2822::ParseError => e
          puts fname
          p e
          p h
        end
      end
    end
  end
  exit
end

require "test/unit"

class TC_RFC2822Parser < Test::Unit::TestCase
  def setup()
    @p = RFC2822::Parser.new()
  end
  def teardown()
  end

  def test_mailbox_list()
    m = @p.parse(:MAILBOX_LIST, "a@b.c")
    assert_equal(1, m.size)
    assert_equal("<a@b.c>", m[0].to_s)
    m = @p.parse(:MAILBOX_LIST, "hoge <a@b.c>")
    assert_equal(1, m.size)
    assert_equal("hoge <a@b.c>", m[0].to_s)
    m = @p.parse(:MAILBOX_LIST, "hoge <a@b.c>, d@e.f")
    assert_equal(2, m.size)
    assert_equal("hoge <a@b.c>", m[0].to_s)
    assert_equal("<d@e.f>", m[1].to_s)
  end

  def test_mailbox()
    m = @p.parse(:MAILBOX, "a@b.c")
    assert_equal("", m.display_name.to_s)
    assert_equal("a@b.c", m.addr_spec.to_s)
    m = @p.parse(:MAILBOX, "hoge <a@b.c>")
    assert_equal("hoge", m.display_name.to_s)
    assert_equal("a@b.c", m.addr_spec.to_s)
    m = @p.parse(:MAILBOX, "hoge fuga <a@b.c>")
    assert_equal("hoge fuga", m.display_name.to_s)
    assert_equal("a@b.c", m.addr_spec.to_s)
  end

  def test_address_list()
    a = @p.parse(:ADDRESS_LIST, "a@b.c")
    assert_equal(1, a.size)
    assert_equal("<a@b.c>", a[0].to_s)
    a = @p.parse(:ADDRESS_LIST, "group:;, hoge <a@b.c>")
    assert_equal(2, a.size)
    assert_equal("group:;", a[0].to_s)
    assert_equal("hoge <a@b.c>", a[1].to_s)
    a = @p.parse(:ADDRESS_LIST, "group: a@b.c, hoge <d@e.f>;")
    assert_equal(1, a.size)
    assert_equal("group:<a@b.c>,hoge <d@e.f>;", a[0].to_s)
  end

  def test_address_list_bcc()
    a = @p.parse(:ADDRESS_LIST_BCC, "")
    assert_equal(0, a.size)
    a = @p.parse(:ADDRESS_LIST_BCC, "a@b.c")
    assert_equal(1, a.size)
    assert_equal("<a@b.c>", a[0].to_s)
    a = @p.parse(:ADDRESS_LIST_BCC, "group:;, hoge <a@b.c>")
    assert_equal(2, a.size)
    assert_equal("group:;", a[0].to_s)
    assert_equal("hoge <a@b.c>", a[1].to_s)
    a = @p.parse(:ADDRESS_LIST_BCC, "group: a@b.c, hoge <d@e.f>;")
    assert_equal(1, a.size)
    assert_equal("group:<a@b.c>,hoge <d@e.f>;", a[0].to_s)
  end

  def test_msg_id()
    m = @p.parse(:MSG_ID, "<a@b.c>")
    assert_equal("<a@b.c>", m.to_s)
  end

  def test_msg_id_list()
    m = @p.parse(:MSG_ID_LIST, "<a@b.c>")
    assert_equal(1, m.size)
    assert_equal("<a@b.c>", m.to_s)
    m = @p.parse(:MSG_ID_LIST, "<a@b.c> <d@e.f>")
    assert_equal(2, m.size)
    assert_equal("<a@b.c> <d@e.f>", m.to_s)
  end

  def test_phrase_list()
    p = @p.parse(:PHRASE_LIST, "hoge")
    assert_equal("hoge", p.to_s)
    p = @p.parse(:PHRASE_LIST, "hoge,fuga")
    assert_equal(2, p.size)
    assert_equal("hoge", p[0].to_s)
    assert_equal("fuga", p[1].to_s)
  end

  def test_date_time_jst()
    d = @p.parse(:DATE_TIME, "25 Sep 2006 01:23:56 +0900")
    assert_equal(2006, d.year)
    assert_equal(9, d.month)
    assert_equal(25, d.day)
    assert_equal(1, d.hour)
    assert_equal(23, d.min)
    assert_equal(56, d.sec)
    assert_equal("+0900", d.zone)
    assert_equal(Time.utc(2006,9,24,16,23,56), d.time)
  end

  def test_date_time_edt()
    d = @p.parse(:DATE_TIME, "25 Sep 2006 01:23:56 -0400")
    assert_equal(2006, d.year)
    assert_equal(9, d.month)
    assert_equal(25, d.day)
    assert_equal(1, d.hour)
    assert_equal(23, d.min)
    assert_equal(56, d.sec)
    assert_equal("-0400", d.zone)
    assert_equal(Time.utc(2006,9,25,5,23,56), d.time)
  end

end

class TC_AddrSpec < Test::Unit::TestCase
  def test_new()
    a = RFC2822::AddrSpec.new("local", "domain") 
    assert_equal("local", a.local_part)
    assert_equal("domain", a.domain)
    assert_equal("local@domain", a.to_s)
  end
end

class TC_Mailbox < Test::Unit::TestCase
  def test_new()
    m = RFC2822::Mailbox.new("local@domain", ["phrase"])
    assert_equal("local@domain", m.addr_spec)
    assert_equal(["phrase"], m.display_name)
    assert_equal(["phrase"], m.phrase)
    assert_equal("phrase <local@domain>", m.to_s)
  end

  def test_new_no_phrase()
    m = RFC2822::Mailbox.new("local@domain")
    assert_equal("local@domain", m.addr_spec)
    assert_equal([], m.display_name)
    assert_equal([], m.phrase)
    assert_equal("<local@domain>", m.to_s)
  end
end

class TC_DateTime < Test::Unit::TestCase
  def test_new_int()
    d = RFC2822::DateTime.new(2006, 9, 25, 23, 56, 10, "+0900")
    assert_equal(2006, d.year)
    assert_equal(9, d.month)
    assert_equal(25, d.day)
    assert_equal(23, d.hour)
    assert_equal(56, d.min)
    assert_equal(10, d.sec)
    assert_equal("+0900", d.zone)
    assert_equal(Time.utc(2006,9,25,14,56,10), d.time)
  end

  def test_new_str()
    d = RFC2822::DateTime.new("2006", "9", "25", "23", "56", "10", "+0900")
    assert_equal(2006, d.year)
    assert_equal(9, d.month)
    assert_equal(25, d.day)
    assert_equal(23, d.hour)
    assert_equal(56, d.min)
    assert_equal(10, d.sec)
    assert_equal("+0900", d.zone)
    assert_equal(Time.utc(2006,9,25,14,56,10), d.time)
  end

  def test_new_obsolete_zone()
    d = RFC2822::DateTime.new("2006", "9", "25", "23", "56", "10", "GMT")
    assert_equal(2006, d.year)
    assert_equal(9, d.month)
    assert_equal(25, d.day)
    assert_equal(23, d.hour)
    assert_equal(56, d.min)
    assert_equal(10, d.sec)
    assert_equal("+0000", d.zone)
    assert_equal(Time.utc(2006,9,25,23,56,10), d.time)
  end

  def test_new_unknown_zone()
    d = RFC2822::DateTime.new("2006", "9", "25", "23", "56", "10", "xxx")
    assert_equal(2006, d.year)
    assert_equal(9, d.month)
    assert_equal(25, d.day)
    assert_equal(23, d.hour)
    assert_equal(56, d.min)
    assert_equal(10, d.sec)
    assert_equal("-0000", d.zone)
    assert_equal(Time.utc(2006,9,25,23,56,10), d.time)
  end
end

class TC_RFC2822 < Test::Unit::TestCase
  def setup()
  end
  def teardown()
  end

  def test_date()
  end

  def test_from()
  end

  def test_sender()
  end

  def test_reply_to()
  end

  def test_to()
  end

  def test_cc()
  end

  def test_bcc()
  end

  def test_message_id()
  end

  def test_in_reply_to()
  end

  def test_references()
  end

  def test_subject()
  end

  def test_comments()
  end

  def test_keywords()
  end

  def test_resent_date()
  end

  def test_resent_from()
  end

  def test_resent_sender()
  end

  def test_resent_to()
  end

  def test_resent_cc()
  end

  def test_resent_bcc()
  end

  def test_resent_message_id()
  end

  def test_return_path()
  end

  def test_received()
  end

  def test_other()
  end

end
