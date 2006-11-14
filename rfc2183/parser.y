#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

class RFC2183::Parser

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
                    pv = $1 if pv =~ /\A\"(.*)\"\Z/
                    val[0][pn] = pv
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

require "rfc2183/scanner"

def parse(header_type, value)
  @header_type = header_type
  @value = value
  @scanner = Scanner.new(header_type, value)
  ret = yyparse(self, :parse_sub)
  @comments = @scanner.comments
  ret
end

def parse_sub(&block)
  yield @header_type, @value
  @scanner.scan(&block)
end

def on_error(t, val, vstack)
#  p t, val, vstack
#  p racc_token2str(t)
  raise ParseError, val
end
