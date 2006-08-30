class RFC2822::Parser

  options no_result_var

rule

all             : MAILBOX_LIST mailbox_list {val[1]}
                | MAILBOX mailbox {val[1]}
                | ADDRESS_LIST address_list {val[1]}
                | ADDRESS_LIST_BCC address_list_bcc {val[1]}
                | MSG_ID msg_id {val[1]}
                | MSG_ID_LIST msg_id_list {val[1]}
                | PHRASE_LIST phrase_list {val[1]}
                | DATE_TIME date_time {val[1]}
                | RETURN_PATH return_path {val[1]}
                | RECEIVED received {val[1]}
                | UNSTRUCTURED UNSTRUCTURED {val[1]}

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

address_list_bcc: address_list
                | cfws_opt
                  {
                    AddressList.new
                  }

address         : mailbox
                | group

mailbox         : name_addr
                | addr_spec
                  {
                    RFC2822::Mailbox.new(val[0], nil)
                  }

name_addr       : angle_addr
                  {
                    RFC2822::Mailbox.new(val[0], nil)
                  }
                | display_name angle_addr
                  {
                    RFC2822::Mailbox.new(val[1], val[0])
                  }

angle_addr_list : angle_addr
                  {
                    [val[0]]
                  }
                | angle_addr_list angle_addr
                  {
                    val[0] << val[1]
                    val[0]
                  }

angle_addr      : cfws_opt '<' addr_spec '>' cfws_opt
                  {
                    val[2]
                  }

group           : display_name ':' cfws_opt ';' cfws_opt
                  {
                    RFC2822::Group.new([], val[0])
                  }
                | display_name ':' mailbox_list ';' cfws_opt
                  {
                    RFC2822::Group.new(val[2], val[0])
                  }

display_name    : phrase

phrase_list     : phrase
                  {
                    RFC2822::PhraseList.new(val[0])
                  }
                | phrase_list ',' phrase
                  {
                    val[0] << val[2]
                    val[0]
                  }

phrase          : word
                  {
                    [val[0]]
                  }
                | phrase word
                  {
                    val[0] << val[1]
                  }

addr_spec       : local_part '@' domain
                  {
                    RFC2822::AddrSpec.new(val[0], val[2])
                  }

local_part      : dot_atom
                | quoted_string

domain          : dot_atom
                | domain_literal

domain_literal  : cfws_opt DOMAIN_LITERAL cfws_opt
                  {
                    val[1]
                  }
                | cfws_opt NO_FOLD_LITERAL cfws_opt
                  {
                    val[1]
                  }

word            : atom
                | quoted_string

atom            : cfws_opt atext_ cfws_opt
                  {
                    val[1]
                  }

atext_          : ATOM
                | DIGIT

dot_atom        : cfws_opt dot_atom_text cfws_opt
                  {
                    val[1]
                  }

dot_atom_text   : atext_
                | dot_atom_text '.' atext_
                  {
                    val.join
                  }

quoted_string   : cfws_opt QUOTED_STRING cfws_opt
                  {
                    val[1]
                  }
                | cfws_opt NO_FOLD_QUOTE cfws_opt
                  {
                    val[1]
                  }

msg_id_list     : msg_id
                  {
                    RFC2822::MsgIdList.new(val[0])
                  }
                | msg_id_list msg_id
                  {
                    val[0] << val[1]
                  }

msg_id          : cfws_opt '<' id_left '@' id_right '>' cfws_opt
                  {
                    RFC2822::MsgId.new(val[1,5].join)
                  }

id_left         : dot_atom_text
                | NO_FOLD_QUOTE

id_right        : dot_atom_text
                | NO_FOLD_LITERAL

return_path     : cfws_opt '<' cfws_opt '>' cfws_opt
                  {
                    RFC2822::ReturnPath.new
                  }
                | cfws_opt '<' cfws_opt addr_spec '>' cfws_opt
                  {
                    RFC2822::ReturnPath.new(val[3])
                  }

received        : name_val_list ';' date_time

name_val_list   : cfws_opt
                  {
                    []
                  }
                | cfws_opt name_val_pair
                  {
                    [val[1]]
                  }
                | name_val_list cfws_opt name_val_pair
                  {
                    val[0] << val[2]
                  }

name_val_pair   : ATOM cfws item_value
                  {
                    unless val[0] =~ /\A[a-zA-Z0-9](-?[a-zA-Z0-9])*\z/ then
                      raise ParseError, val[0]
                    end
                    [val[0], val[2]]
                  }

item_value      : angle_addr_list
                | addr_spec
                | atom
                | domain
                | msg_id

fws_opt         : /* empty */
                | FWS

cfws_opt        : /* empty */
                | cfws

cfws            : CFWS
                | FWS

date_time       : day_of_week fws_opt DIGIT FWS ATOM FWS DIGIT FWS time_of_day FWS zone cfws_opt
                  {
                    year, month, day, time, zone = val.values_at(6,4,2,8,10)
                    raise ParseError, year unless year =~ /\A\d\d\d\d\Z/
                    raise ParseError, month unless ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"].include? month.downcase
                    raise ParseError, day unless day =~ /\A\d?\d\Z/
                  }

day_of_week     : fws_opt
                | fws_opt ATOM ','
                  {
                    unless ['mon','tue','wed','thu','fri','sat','sun'].include? val[1].downcase then
                      raise ParseError, val[1]
                    end
                  }

time_of_day     : DIGIT ':' DIGIT
                  {
                    val.join+":00"
                  }
                | DIGIT ':' DIGIT ':' DIGIT
                  {
                    val.join
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
