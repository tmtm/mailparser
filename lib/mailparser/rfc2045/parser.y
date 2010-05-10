# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

class MailParser::RFC2045::Parser

  options no_result_var

rule

all             : CONTENT_TYPE content_type {val[1]}
#               | CONTENT_DESCRIPTION
                | CONTENT_TRANSFER_ENCODING content_transfer_encoding {val[1]}
#               | CONTENT_ID content_id {val[1]}
                | MIME_VERSION mime_version {val[1]}

content_type    : type '/' subtype parameter_list
                  {
                    ContentType.new(val[0], val[2], val[3])
                  }

content_transfer_encoding: mechanism
                  {
                    ContentTransferEncoding.new(val[0])
                  }

#content_id      : msg_id

mime_version    : DIGIT '.' DIGIT
                  {
                    val.join
                  }

mechanism       : TOKEN

type            : TOKEN

subtype         : TOKEN

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

require "mailparser/rfc2045/scanner"

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
