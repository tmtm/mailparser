#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "strscan"

class RFC2822::Scanner
  TEXT_RE = '\x00-\x7f'
  QTEXT_RE = '\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f'
  ATEXT_RE = 'A-Za-z0-9\!\#\$\%\&\'\*\+\\-\/\=\?\^\_\`\{\|\}\~'
  CTEXT_RE = '\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x27\x2a-\x5b\x5d-\x7f'
  UTEXT_RE = '\x00-\x7f'
  DTEXT_RE = '\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x5e-\x7e'

  def initialize(header_type, str)
    @header_type = header_type
    @comments = []
    @ss = StringScanner.new(str)
  end

  attr_reader :comments

  def scan(&block)
    case @header_type
    when :UNSTRUCTURED
      scan_unstructured(&block)
    else
      scan_structured(&block)
    end
  end

  def scan_unstructured()
    if @ss.eos? then
      yield :UNSTRUCTURED, ""
      yield nil
      return
    end
    until @ss.eos?
      if s = @ss.scan(/(\s*|[#{UTEXT_RE}])*\s*/no) then
        yield :UNSTRUCTURED, s
      end
    end 
    yield nil
  end

  def scan_structured()
    until @ss.eos?
      case
      when s = @ss.scan(/\s*\(/nmo)
        cfws(@ss)
        next
      when s = @ss.scan(/\s+/nmo)
        next
      when s = @ss.scan(/\"(\\[#{TEXT_RE}]|[#{QTEXT_RE}])*\"/no)
        yield :NO_FOLD_QUOTE, s
      when s = @ss.scan(/\"(\s*(\\[#{TEXT_RE}]|[#{QTEXT_RE}]))*\s*\"/nmo)
        yield :QUOTED_STRING, s
      when s = @ss.scan(/\[(\\[#{TEXT_RE}]|[#{DTEXT_RE}])*\]/no)
        yield :NO_FOLD_LITERAL, s
      when s = @ss.scan(/\[(\s*(\\[#{TEXT_RE}]|[#{DTEXT_RE}]))*\s*\]/nmo)
        yield :DOMAIN_LITERAL, s
      when s = @ss.scan(/[#{ATEXT_RE}]+/no)
        if s =~ /\A\d+\z/ then
          yield :DIGIT, s
        else
          yield :ATOM, s
        end
      when s = @ss.scan(/./no)
        yield s, s
      end
    end
    yield nil
  end

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
        raise RFC2822::ParseError, ss.rest
      end
    end
    # 「)」がなかったら例外
    raise RFC2822::ParseError, ss.rest
  end
end
