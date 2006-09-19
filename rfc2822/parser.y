class RFC2822::Parser

  options no_result_var

rule

all             : MAILBOX_LIST mailbox_list
                | MAILBOX mailbox
                | ADDRESS_LIST address_list
                | ADDRESS_LIST_BCC address_list_bcc
                | MSG_ID msg_id
                | MSG_ID_LIST msg_id_list
                | PHRASE_LIST phrase_list
                | DATE_TIME date_time
                | RETURN_PATH return_path
                | RECEIVED received
                | UNSTRUCTURED UNSTRUCTURED

mailbox_list    : mailbox
                  {
                    RFC2822::MailboxList.new(val[0])
                  }
                | mailbox_list ',' mailbox
                  {
                    val[0] << val[2]
                    val[0]
                  }

address_list    : address
                  {
                    RFC2822::AddressList.new(val[0])
                  }
                | address_list ',' address
                  {
                    val[0] << val[2]
                    val[0]
                  }

address_list_bcc: /* empty */
                | address_list

address         : mailbox
                | group

mailbox         : name_addr
                | addr_spec

name_addr       : angle_addr
                | display_name angle_addr

angle_addr_list : angle_addr
                | angle_addr_list angle_addr

angle_addr      : '<' addr_spec '>'

group           : display_name ':' ';'
                | display_name ':' mailbox_list ';'

display_name    : phrase

phrase_list     : phrase
                | phrase_list ',' phrase

phrase          : word
                | phrase word

addr_spec       : local_part '@' domain

local_part      : dot_atom
                | quoted_string

domain          : dot_atom
                | domain_literal

domain_literal  : DOMAIN_LITERAL
                | NO_FOLD_LITERAL

word            : atom
                | quoted_string

atom            : ATOM

dot_atom        : dot_atom_text

dot_atom_text   : atom
                | dot_atom_text '.' atom

quoted_string   : QUOTED_STRING
                | NO_FOLD_QUOTE

msg_id_list     : msg_id
                | msg_id_list msg_id

msg_id          : ws_mode cfws_opt '<' id_left '@' id_right '>' no_ws_mode

id_left         : dot_atom_text
                | NO_FOLD_QUOTE

id_right        : dot_atom_text
                | NO_FOLD_LITERAL

return_path     : '<' '>'
                | '<' addr_spec '>'

received        : name_val_list ';' date_time

name_val_list   : /* empty */
                | name_val_list name_val_pair

name_val_pair   : ATOM item_value
                  {
                    unless val[0] =~ /\A[a-zA-Z0-9](-?[a-zA-Z0-9])*\z/ then
                      raise ParseError, val[0]
                    end
                    [val[0], val[2]]
                  }

item_value      : angle_addr_list
                | addr_spec
#               | atom    /* domain include atom */
                | dot_atom       /* extracted from domain */
                | domain_literal /* extracted from domain */
#               | msg_id  /* angle_addr_list include msg_id */

fws_opt         : /* empty */
                | FWS

cfws_opt        : /* empty */
                | cfws

cfws            : CFWS
                | FWS

ws_mode         : /* empty */
                  {
                    @scanner.ws_mode = true
                  }

no_ws_mode      : /* empty */
                  {
                    @scanner.ws_mode = false
                  }

datetime_mode   : /* empty */
                  {
                    @scanner.ws_mode = true
                    @scanner.datetime_mode = true
                  }

no_datetime_mode: /* empty */
                  {
                    @scanner.ws_mode = false
                    @scanner.datetime_mode = false
                  }

date_time       : datetime_mode fws_opt day_of_week DIGIT FWS ATOM FWS DIGIT FWS TIME_OF_DAY FWS zone no_datetime_mode
                  {
                    year, month, day, time, zone = val.values_at(7,5,3,9,11)
                    raise ParseError, year unless year =~ /\A\d\d\d\d\Z/
                    raise ParseError, month unless ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"].include? month.downcase
                    raise ParseError, day unless day =~ /\A\d?\d\Z/
                  }

day_of_week     : /* empty */
                | ATOM ',' fws_opt
                  {
                    unless ['mon','tue','wed','thu','fri','sat','sun'].include? val[0].downcase then
                      raise ParseError, val[0]
                    end
                  }

zone            : ATOM
                  {
                    raise ParseError, val[0] unless val[0] =~ /\A[+-]\d\d\d\d\Z/
                    val[0]
                  }

end

---- inner

require "rfc2822/scanner"

def parse(header_type, value)
  @header_type = header_type
  @value = value
  @scanner = RFC2822::Scanner.new(@header_type, value)
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
