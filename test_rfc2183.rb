#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "rfc2183"

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
          RFC2183.parse(*h.split(/\s*:\s*/, 2))
        rescue RFC2183::ParseError => e
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

class TC_RFC2183 < Test::Unit::TestCase
  def test_content_disposition_noparams()
    c = RFC2183.parse("content-disposition", "inline")
    assert_equal("inline", c.type)
    assert_equal({}, c.params)
  end

  def test_content_disposition_charset()
    c = RFC2183.parse("content-disposition", "inline; filename=hoge")
    assert_equal("inline", c.type)
    assert_equal(1, c.params.size)
    assert_equal("hoge", c.params["filename"])
  end

  def test_content_disposition_charset_upcase()
    c = RFC2183.parse("content-disposition", "INLINE; FILENAME=HOGE")
    assert_equal("inline", c.type)
    assert_equal("HOGE", c.params["filename"])
  end

  def test_content_disposition_charset_quote()
    c = RFC2183.parse("content-disposition", "inline; filename=\"hoge\"")
    assert_equal("inline", c.type)
    assert_equal(1, c.params.size)
    assert_equal("hoge", c.params["filename"])
  end
end
