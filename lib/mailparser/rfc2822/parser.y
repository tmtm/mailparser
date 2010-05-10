# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

class MailParser::RFC2822::Parser

  options no_result_var

rule

all             : MAILBOX_LIST mailbox_list {val[1]}
                | MAILBOX mailbox {val[1]}
                | ADDRESS_LIST address_list {val[1]}
                | ADDRESS_LIST_BCC address_list {val[1]}
                | MSG_ID msg_id {val[1]}
                | MSG_ID_LIST msg_id_list {val[1]}
                | PHRASE_LIST phrase_list {val[1]}
                | PHRASE_MSG_ID_LIST phrase_msg_id_list {val[1]}
                | DATE_TIME date_time {val[1]}
                | RETURN_PATH return_path {val[1]}
                | RECEIVED received {val[1]}
                | UNSTRUCTURED UNSTRUCTURED {val[1]}

mailbox_list    : mailbox_list_
                  {
                    unless val[0].empty? then
                      val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-1], nil))
                    end
                    val[0]
                  }

mailbox_list_   : mailbox_opt
                  {
                    val[0] ? [val[0]] : []
                  }
                | mailbox_list_ ',' mailbox_opt
                  {
                    @comma_list << val[1].object_id
                    val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-2], @comma_list[-1])) if val[0].last.kind_of? Mailbox
                    val[0] << val[2] if val[2]
                    val[0]
                  }

mailbox_opt     : /* empty */
                | mailbox

address_list    : address_list_
                  {
                    if not val[0].empty? and val[0].last.kind_of? Mailbox then
                      val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-1], nil))
                    end
                    val[0]
                  }

address_list_   : address_opt
                  {
                    val[0] ? [val[0]] : []
                  }
                | address_list_ ',' address_opt
                  {
                    @comma_list << val[1].object_id
                    if val[0].last.kind_of? Mailbox then
                      val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-2], @comma_list[-1]))
                    end
                    val[0] << val[2] if val[2]
                    val[0]
                  }

address_opt     : /* empty */
                | address

address         : mailbox
                | group

mailbox         : name_addr
                | addr_spec
                  {
                    Mailbox.new(val[0])
                  }

name_addr       : angle_addr
                  {
                    Mailbox.new(val[0])
                  }
                | display_name angle_addr
                  {
                    Mailbox.new(val[1], val[0])
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

angle_addr      : '<' addr_spec '>'
                  {
                    val[1]
                  }
                | '<' obs_route addr_spec '>'
                  {
                    val[2]
                  }

obs_route       : obs_domain_list ':'

obs_domain_list : '@' domain
                | obs_domain_list obs_domain_list_delim '@' domain

obs_domain_list_delim : /* empty */
                      | obs_domain_list_delim ','

#group           : display_name ':' ';'       /* mailbox_list may be empty */
group           : display_name ':' mailbox_list ';'
                  {
                    Group.new(val[2], val[0])
                  }

display_name    : phrase
                  {
                    decode(val[0])
                  }

phrase_list     : phrase_opt
                  {
                    [val[0]].compact
                  }
                | phrase_list ',' phrase_opt
                  {
                    val[0] << val[2] if val[2]
                    val[0]
                  }

phrase_opt      : /* empty */
                | phrase
                  {
                    decode(val[0])
                  }

phrase0         : local_part
                | word_dot_list_dot

phrase          : phrase0
                  {
                    val[0].to_s
                  }
                | phrase word
                  {
                    val[0] << " #{val[1]}"
                  }

addr_spec       : local_part '@' domain
                  {
                    AddrSpec.new(val[0], val[2])
                  }

local_part      : word
                | word_dot_list word
                  {
                    val.join
                  }
                | atom_dot_list word
                  {
                    val.join
                  }

domain          : atom
                | atom_dot_list atom
                  {
                    val.join
                  }
                | domain_literal

domain_literal  : DOMAIN_LITERAL
                | NO_FOLD_LITERAL

word            : atom
                | quoted_string

atom            : ATOM
                | DIGIT

word_dot_list   : quoted_string '.'
                  {
                    val.join
                  }
                | word_dot_list quoted_string '.'
                  {
                    val[0] << val[1]+val[2]
                  }
                | atom_dot_list quoted_string '.'
                  {
                    val[0] << val[1]+val[2]
                  }

word_dot_list_dot : word_dot_list '.'
                  {
                    val.join
                  }
                | word_dot_list_dot '.'
                  {
                    val.join
                  }

atom_dot_list   : atom '.'
                  {
                    val.join
                  }
                | atom_dot_list atom '.'
                  {
                    val.join
                  }

quoted_string   : QUOTED_STRING
                | NO_FOLD_QUOTE

msg_id_list     : msg_id
                  {
                    MsgIdList.new(val[0])
                  }
                | msg_id_list msg_id
                  {
                    val[0] << val[1]
                  }

msg_id          : '<' id_left '@' id_right '>'
                  {
                    MsgId.new(val[1,3].join)
                  }

phrase_msg_id_list : /* empty */
                  {
                    MsgIdList.new()
                  }
                 | phrase_msg_id_list phrase0
                 | phrase_msg_id_list msg_id
                  {
                    val[0] << val[1]
                  }

#id_left         : dot_atom_text  /* local_part include dot_atom_text */
#                | NO_FOLD_QUOTE  /* local_part include NO_FOLD_QUOTE */
id_left          : local_part

#id_right        : dot_atom_text   /* domain include dot_atom_text */
#                | NO_FOLD_LITERAL /* domain include NO_FOLD_LITERAL */
id_right         : domain

return_path     : '<' '>'
                  {
                    nil
                  }
#               | '<' addr_spec '>'    /* -> angle_addr */
                | angle_addr

received        : name_val_list ';' date_time
                  {
                    Received.new(val[0], val[2])
                  }

name_val_list   : /* empty */
                  {
                    {}
                  }
                | name_val_list name_val_pair
                  {
                    val[0][val[1][0]] = val[1][1]
                    val[0]
                  }

name_val_pair   : ATOM item_value
                  {
                    unless val[0] =~ /\A[a-zA-Z0-9](-?[a-zA-Z0-9])*\z/ then
                      raise MailParser::ParseError, val[0]+@scanner.rest
                    end
                    [val[0].downcase, val[1].to_s]
                  }

item_value      : angle_addr_list
                | addr_spec
#               | atom    /* domain include atom */
                | domain
#               | msg_id  /* angle_addr_list include msg_id */

date_time       : day_of_week DIGIT ATOM DIGIT time_of_day zone
                  {
                    year, month, day, time, zone = val.values_at(3,2,1,4,5)
                    raise MailParser::ParseError, "invalid year: #{year}" unless year =~ /\A\d\d\d\d\Z/
                    m = [nil,"jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"].index month.downcase
                    raise MailParser::ParseError, "invaild month: #{month}" unless m
                    raise MailParser::ParseError, "invalid day of the month: #{day}" unless day =~ /\A\d?\d\Z/
                    begin
                      DateTime.new(year.to_i, m.to_i, day.to_i, time[0], time[1], time[2], zone)
                    rescue ArgumentError
                      raise MailParser::ParseError, "invalid date format"
                    end
                  }

day_of_week     : /* empty */
                | ATOM ','
                  {
                    unless ['mon','tue','wed','thu','fri','sat','sun'].include? val[0].downcase then
                      raise MailParser::ParseError, "invalid day of the week: #{val[0]}"
                    end
                  }

time_of_day     : DIGIT ':' DIGIT
                  {
                    if val[0] !~ /\A\d\d\Z/ or val[0].to_i > 23 then
                      raise MailParser::ParseError, "invalid hour: #{val[0]}"
                    end
                    if val[2] !~ /\A\d\d\Z/ or val[2].to_i > 59 then
                      raise MailParser::ParseError, "invalid minute: #{val[2]}"
                    end
                    [val[0].to_i, val[2].to_i, 0]
                  }
                | DIGIT ':' DIGIT ':' DIGIT
                  {
                    if val[0] !~ /\A\d\d\Z/ or val[0].to_i > 23 then
                      raise MailParser::ParseError, "invalid hour: #{val[0]}"
                    end
                    if val[2] !~ /\A\d\d\Z/ or val[2].to_i > 59 then
                      raise MailParser::ParseError, "invalid minute: #{val[2]}"
                    end
                    if val[4] !~ /\A\d\d\Z/ or val[4].to_i > 60 then
                      raise MailParser::ParseError, "invalid second: #{val[4]}"
                    end
                    [val[0].to_i, val[2].to_i, val[4].to_i]
                  }

zone            : ATOM
                  {
                    if val[0] =~ /\A[+-]\d\d\d\d\Z/ then
                      val[0]
                    else
                      ZONE[val[0].upcase] || "-0000"
                    end
                  }

end

---- inner

require "mailparser/rfc2822/scanner"

def initialize(opt={})
  @opt = opt
  super()
end

def parse(header_type, value)
  @header_type = header_type
  @value = value
  @last_id = nil
  @comma_list = []
  @scanner = Scanner.new(header_type, value)
  ret = yyparse(self, :parse_sub)
  class << ret
    attr_accessor :comments
  end
  ret.comments = decode2(@scanner.comments)
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

def decode(s)
  return s unless @opt[:decode_mime_header]
  RFC2047.decode(s, @opt)
end

def decode2(ary)
  ary.map{|i| decode(i)}
end
