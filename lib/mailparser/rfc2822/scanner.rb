# -*- coding: utf-8 -*-
# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "strscan"

class MailParser::RFC2822::Scanner
  TEXT_RE = '\x00-\x7f'
  QTEXT_RE = '\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f'
  ATEXT_RE = 'A-Za-z0-9\!\#\$\%\&\'\*\+\\-\/\=\?\^\_\`\{\|\}\~'
  CTEXT_RE = '\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x27\x2a-\x5b\x5d-\x7f'
  UTEXT_RE = '\x00-\x7f'
  DTEXT_RE = '\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x5e-\x7e'

  def initialize(header_type, str)
    @header_type = header_type
    @comments = []
    @token = []
    @token_idx = {}
    @ss = StringScanner.new(str)
  end

  attr_reader :comments

  def scan()
    until @ss.eos?
      case
      when s = @ss.scan(/\s*\(/nmo)
        @token << cfws(@ss)
        @token_idx[@token.last.object_id] = @token.size-1
      when s = @ss.scan(/\s+/nmo)
        @token << s
        @token_idx[s.object_id] = @token.size-1
      when s = @ss.scan(/\"(\\[#{TEXT_RE}]|[#{QTEXT_RE}])*\"/no)
        @token << s
        @token_idx[s.object_id] = @token.size-1
        yield :NO_FOLD_QUOTE, s
      when s = @ss.scan(/\"(\s*(\\[#{TEXT_RE}]|[#{QTEXT_RE}]))*\s*\"/nmo)
        @token << s
        @token_idx[s.object_id] = @token.size-1
        yield :QUOTED_STRING, s
      when s = @ss.scan(/\[(\\[#{TEXT_RE}]|[#{DTEXT_RE}])*\]/no)
        @token << s
        @token_idx[s.object_id] = @token.size-1
        yield :NO_FOLD_LITERAL, s
      when s = @ss.scan(/\[(\s*(\\[#{TEXT_RE}]|[#{DTEXT_RE}]))*\s*\]/nmo)
        @token << s
        @token_idx[s.object_id] = @token.size-1
        yield :DOMAIN_LITERAL, s
      when s = @ss.scan(/[#{ATEXT_RE}]+/no)
        @token << s
        @token_idx[s.object_id] = @token.size-1
        if s =~ /\A\d+\z/ then
          yield :DIGIT, s
        else
          yield :ATOM, s
        end
      when s = @ss.scan(/./no)
        @token << s
        @token_idx[s.object_id] = @token.size-1
        yield s, s
      end
    end
    yield nil
  end

  def rest()
    @ss.rest
  end

  # 「(」の直後からコメント部の終わりまでスキャン
  def cfws(ss)
    comments = []
    while true
      c = cfws_sub(ss)
      ss.skip(/\s+/nmo)
      comments << "(#{c})"
      break unless @ss.scan(/\(/no)
    end
    @comments.concat comments
    return comments.join
  end

  # コメント部の処理
  # return: コメント部の文字列
  def cfws_sub(ss)
    ret = ""
    until ss.eos? do
      if ss.scan(/(\s*(\\[#{TEXT_RE}]|[#{CTEXT_RE}]))*\s*/nmo) then
        ret << ss.matched
      end
      if ss.scan(/\)/no) then      # 「)」が来たら復帰
        return ret
      elsif ss.scan(/\(/no) then      # 「(」が来たら再帰
        c = cfws_sub(ss)
        break if c.nil?
        ret << "(" << c << ")"
      else
        raise MailParser::ParseError, ss.rest
      end
    end
    # 「)」がなかったら例外
    raise MailParser::ParseError, ss.rest
  end

  # @token中の位置が s から e までの間のコメント文字列の配列を得る
  def get_comment(s, e)
    a = @token[s..e].select{|i| i =~ /^\s*\(/}.map{|i| i.strip}
    return a
  end

  # @token中の object_id が s_id から e_id までの間のコメント文字列の配列を得る
  def get_comment_by_id(s_id, e_id)
    s = s_id ? @token_idx[s_id] : 0
    e = e_id ? @token_idx[e_id] : -1
    return get_comment(s, e)
  end

end
