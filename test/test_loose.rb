# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/loose"
require "test/unit"

class TC_Loose < Test::Unit::TestCase
  include MailParser::Loose

  def setup()
  end
  def teardown()
  end

  def test_parse_date()
    d = parse_date("Wed, 10 Jan 2007 12:53:55 +0900")
    assert_equal(2007, d.year)
    assert_equal(1, d.month)
    assert_equal(10, d.day)
    assert_equal(12, d.hour)
    assert_equal(53, d.min)
    assert_equal(55, d.sec)
    assert_equal("+0900", d.zone)
  end

  def test_parse_phrase_list()
    p = parse_phrase_list("abc def, ghi jkl")
    assert_equal(2, p.size)
    assert_equal("abc def", p[0])
    assert_equal("ghi jkl", p[1])
  end

  def test_parse_phrase_list_mime()
    p = parse_phrase_list("abc =?us-ascii?q?def?=, ghi jkl", :decode_mime_header=>true)
    assert_equal(2, p.size)
    assert_equal("abc def", p[0])
    assert_equal("ghi jkl", p[1])
  end

  def test_parse_received()
    r = parse_received("from host.example.com by my.server for <user@domain.name>; Wed, 10 Jan 2007 12:09:55 +0900")
    assert_equal(2007, r.date_time.year)
    assert_equal(1, r.date_time.month)
    assert_equal(10, r.date_time.day)
    assert_equal(12, r.date_time.hour)
    assert_equal(9, r.date_time.min)
    assert_equal(55, r.date_time.sec)
    assert_equal("+0900", r.date_time.zone)
    assert_equal("host.example.com", r.name_val["from"])
    assert_equal("my.server", r.name_val["by"])
    assert_equal("<user@domain.name>", r.name_val["for"])
  end

  def test_parse_content_type()
    ct = parse_content_type("text/plain; charset=iso-2022-jp")
    assert_equal("text", ct.type)
    assert_equal("plain", ct.subtype)
    assert_equal({"charset"=>"iso-2022-jp"}, ct.params)
  end

  def test_parse_content_type_miss()
    ct = parse_content_type("text")
    assert_equal("text", ct.type)
    assert_equal("plain", ct.subtype)
    assert_equal({}, ct.params)
  end

  def test_parse_content_type_name()
    ct = parse_content_type("text/plain; name=hoge.txt")
    assert_equal("text", ct.type)
    assert_equal("plain", ct.subtype)
    assert_equal({"name"=>"hoge.txt"}, ct.params)
  end

  def test_parse_content_type_name_quoted()
    ct = parse_content_type("text/plain; name=\"hoge.txt\"")
    assert_equal("text", ct.type)
    assert_equal("plain", ct.subtype)
    assert_equal({"name"=>"hoge.txt"}, ct.params)
  end

  def test_parse_content_disposition()
    c = parse_content_disposition("attachment; filename=hoge.txt")
    assert_equal("attachment", c.type)
    assert_equal({"filename"=>"hoge.txt"}, c.params)
  end

  def test_parse_content_disposition_quoted()
    c = parse_content_disposition("attachment; filename=\"hoge.txt\"")
    assert_equal("attachment", c.type)
    assert_equal({"filename"=>"hoge.txt"}, c.params)
  end

  def test_split_by()
    assert_equal([["aa","bb"],["cc"],["dd"]], split_by(%w(aa bb , cc , dd), ","))
  end

  def test_mailbox_list()
    ml = mailbox_list("hoge <hoge@example.com>, fuga@example.net", {})
    assert_equal(2, ml.size)
    assert_equal("hoge", ml[0].phrase)
    assert_equal("hoge", ml[0].addr_spec.local_part)
    assert_equal("example.com", ml[0].addr_spec.domain)
    assert_equal("", ml[1].phrase)
    assert_equal("fuga", ml[1].addr_spec.local_part)
    assert_equal("example.net", ml[1].addr_spec.domain)
  end

  def test_mailbox_list2()
    ml = mailbox_list("hoge hoge (comment) <hoge.hoge@example.com>", {})
    assert_equal(1, ml.size)
    assert_equal("hoge hoge", ml[0].phrase)
    assert_equal("hoge.hoge", ml[0].addr_spec.local_part)
    assert_equal("example.com", ml[0].addr_spec.domain)
  end

  def test_msg_id_list_old_in_reply_to()
    assert_equal("<local-part@domain.name>", msg_id_list("hoge@hoge.hoge message <local-part@domain.name>").to_s)
  end

end

class TC_Loose_Tokenizer < Test::Unit::TestCase
  include MailParser::Loose

  def setup()
  end
  def teardown()
  end

  def test_token()
    assert_equal(["a",",","b",",","c"], Tokenizer.token("a,b,c"))
  end

  def test_token2()
    assert_equal(["a/b/c"], Tokenizer.token("a/b/c"))
  end

  def test_token_quoted_string()
    assert_equal(["\"a,b,c\"",",","d",",","e"], Tokenizer.token("\"a,b,c\",d,e"))
  end

  def test_token_quoted_string2()
    assert_equal(["\"ab\\\"c\"",",","d",",","e"], Tokenizer.token("\"ab\\\"c\",d,e"))
  end

  def test_token_comment()
    assert_equal(["aa",",","cc",",","ee"], Tokenizer.token("aa(bb),cc(dd),ee"))
  end

  def test_token_nested_comment()
    assert_equal(["aa",",","cc",",","ee"], Tokenizer.token("aa(bb(xx)),cc(dd),ee"))
  end

  def test_token_invalid_comment()
    assert_equal(["aa","(","bb","(","xx",",","cc",",","ee"], Tokenizer.token("aa(bb(xx,cc(dd),ee"))
  end

  def test_token_received()
    assert_equal(["aa","bb","cc"], Tokenizer.token_received("aa bb cc"))
  end

  def test_token_received_comment()
    assert_equal(["a","b","c"], Tokenizer.token_received("a(hoge)b(hoge)c"))
  end

  def test_token_received_quotedstring()
    assert_equal(["\"a b c\"", "<a@b.c>"], Tokenizer.token_received("\"a b c\" <a@b.c>"))
  end

  def test_token_received_semicolon()
    assert_equal(["a","b",";","d","e"], Tokenizer.token_received("a b;d e"))
  end

end
