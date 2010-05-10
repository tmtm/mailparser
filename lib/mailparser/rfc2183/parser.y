# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

class MailParser::RFC2183::Parser

  options no_result_var

rule

all             : CONTENT_DISPOSITION content_disposition {val[1]}

content_disposition : type parameter_list
                  {
                    ContentDisposition.new(val[0], val[1])
                  }

type            : TOKEN

parameter_list  : /* empty */
                  {
                    {}
                  }
                | parameter_list ';' parameter
                  {
                    pn, pv = val[2]
                    pv = $1 if pv =~ /\A\"(.*)\"\Z/m
                    val[0][pn] = pv.gsub(/\s*\n\s*/, " ")
                    val[0]
                  }

parameter       : attribute '=' value
                  {
                    [val[0].downcase, val[2]]
                  }

attribute       : TOKEN

value           : TOKEN
                | QUOTED_STRING

---- inner

require "mailparser/rfc2183/scanner"

def parse(header_type, value)
  @header_type = header_type
  @value = value
  @scanner = Scanner.new(header_type, value)
  ret = yyparse(self, :parse_sub)
  class << ret
    attr_accessor :comments
  end
  ret.comments = @scanner.comments
  ret
end

def parse_sub(&block)
  yield @header_type, nil
  @scanner.scan(&block)
end

def on_error(t, val, vstack)
#  p t, val, vstack
#  p racc_token2str(t)
  raise MailParser::ParseError, val+@scanner.rest
end
