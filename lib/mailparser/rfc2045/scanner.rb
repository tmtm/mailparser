# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/rfc2822"

class MailParser::RFC2045::Scanner < MailParser::RFC2822::Scanner
  TOKEN_RE = '\x21\x23-\x27\x2a\x2b\x2d\x2e\x30-\x39\x41-\x5a\x5e-\x7f'

  def scan(&block)
    case @header_type
    when :MIME_VERSION
      scan_mime_version(&block)
    else
      scan_structured(&block)
    end
  end

  def scan_structured()
    until @ss.eos?
      case
      when s = @ss.scan(/\s*\(/nmo)
        s << cfws(@ss)
        next
      when s = @ss.scan(/\s+/nmo)
        next
      when s = @ss.scan(/\"(\s*(\\[#{TEXT_RE}]|[#{QTEXT_RE}]))*\s*\"/nmo)
        yield :QUOTED_STRING, s
      when s = @ss.scan(/[#{TOKEN_RE}]+/no)
        yield :TOKEN, s
      when s = @ss.scan(/./no)
        yield s, s
      end
    end
    yield nil
  end

  def scan_mime_version()
    until @ss.eos?
      case
      when s = @ss.scan(/\s*\(/nmo)
        s << cfws(@ss)
        next
      when s = @ss.scan(/\s+/nmo)
        next
      when s = @ss.scan(/\d+/no)
        yield :DIGIT, s
      when s = @ss.scan(/./no)
        yield s, s
      end
    end
    yield nil
  end

end
