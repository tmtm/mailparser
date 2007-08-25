#
# DO NOT MODIFY!!!!
# This file is automatically generated by racc 1.4.5
# from racc grammer file "lib/mailparser/rfc2822/parser.y".
#

require 'racc/parser'


module MailParser

  module RFC2822

    class Parser < Racc::Parser

module_eval <<'..end lib/mailparser/rfc2822/parser.y modeval..id5542ab9cf1', 'lib/mailparser/rfc2822/parser.y', 345

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
  RFC2047.decode(s, @opt[:output_charset])
end

def decode2(ary)
  ary.map{|i| decode(i)}
end
..end lib/mailparser/rfc2822/parser.y modeval..id5542ab9cf1

##### racc 1.4.5 generates ###

racc_reduce_table = [
 0, 0, :racc_error,
 2, 28, :_reduce_1,
 2, 28, :_reduce_2,
 2, 28, :_reduce_3,
 2, 28, :_reduce_4,
 2, 28, :_reduce_5,
 2, 28, :_reduce_6,
 2, 28, :_reduce_7,
 2, 28, :_reduce_8,
 2, 28, :_reduce_9,
 2, 28, :_reduce_10,
 2, 28, :_reduce_11,
 2, 28, :_reduce_12,
 1, 29, :_reduce_13,
 1, 39, :_reduce_14,
 3, 39, :_reduce_15,
 0, 40, :_reduce_none,
 1, 40, :_reduce_none,
 1, 31, :_reduce_18,
 1, 41, :_reduce_19,
 3, 41, :_reduce_20,
 0, 42, :_reduce_none,
 1, 42, :_reduce_none,
 1, 43, :_reduce_none,
 1, 43, :_reduce_none,
 1, 30, :_reduce_none,
 1, 30, :_reduce_26,
 1, 45, :_reduce_27,
 2, 45, :_reduce_28,
 1, 49, :_reduce_29,
 2, 49, :_reduce_30,
 3, 47, :_reduce_31,
 4, 47, :_reduce_32,
 2, 50, :_reduce_none,
 2, 51, :_reduce_none,
 4, 51, :_reduce_none,
 0, 53, :_reduce_none,
 2, 53, :_reduce_none,
 4, 44, :_reduce_38,
 1, 48, :_reduce_39,
 1, 34, :_reduce_40,
 3, 34, :_reduce_41,
 0, 55, :_reduce_none,
 1, 55, :_reduce_43,
 1, 56, :_reduce_none,
 1, 56, :_reduce_none,
 1, 54, :_reduce_46,
 2, 54, :_reduce_47,
 3, 46, :_reduce_48,
 1, 57, :_reduce_none,
 2, 57, :_reduce_50,
 2, 57, :_reduce_51,
 1, 52, :_reduce_none,
 2, 52, :_reduce_53,
 1, 52, :_reduce_none,
 1, 63, :_reduce_none,
 1, 63, :_reduce_none,
 1, 59, :_reduce_none,
 1, 59, :_reduce_none,
 1, 62, :_reduce_none,
 1, 62, :_reduce_none,
 2, 60, :_reduce_61,
 3, 60, :_reduce_62,
 3, 60, :_reduce_63,
 2, 58, :_reduce_64,
 2, 58, :_reduce_65,
 2, 61, :_reduce_66,
 3, 61, :_reduce_67,
 1, 64, :_reduce_none,
 1, 64, :_reduce_none,
 1, 33, :_reduce_70,
 2, 33, :_reduce_71,
 5, 32, :_reduce_72,
 0, 35, :_reduce_73,
 2, 35, :_reduce_none,
 2, 35, :_reduce_75,
 1, 65, :_reduce_none,
 1, 66, :_reduce_none,
 2, 37, :_reduce_78,
 1, 37, :_reduce_none,
 3, 38, :_reduce_80,
 0, 67, :_reduce_81,
 2, 67, :_reduce_82,
 2, 68, :_reduce_83,
 1, 69, :_reduce_none,
 1, 69, :_reduce_none,
 1, 69, :_reduce_none,
 6, 36, :_reduce_87,
 0, 70, :_reduce_none,
 2, 70, :_reduce_89,
 3, 71, :_reduce_90,
 5, 71, :_reduce_91,
 1, 72, :_reduce_92 ]

racc_reduce_n = 93

racc_shift_n = 148

racc_action_table = [
     4,     5,     6,     7,     8,    10,    11,    12,    13,     1,
     2,     3,    51,    20,    21,    61,    26,    29,   -57,    20,
    21,    31,    26,    29,   120,    99,   106,   107,    20,    21,
    31,    26,    29,   -57,    31,    31,    89,    20,    21,    85,
    26,    29,    20,    21,    31,    26,    29,    73,    74,    31,
    71,    20,    21,   100,    26,    29,    20,    21,    31,    26,
    29,    20,    21,    31,    84,    20,    21,    31,    26,    29,
    20,    21,    31,    26,    29,    85,   108,   130,    75,    20,
    21,   131,    26,    29,    66,    61,    69,    86,   119,   120,
    20,    21,    69,    26,    29,   121,    20,    21,    74,    26,
    29,    20,    21,    95,    26,    29,    20,    21,    98,    26,
    29,    20,    21,   125,    26,    29,    20,    21,    51,    26,
    29,    20,    21,   127,    26,    29,    20,    21,   128,    26,
    29,    20,    21,    51,    26,    29,    20,    21,    85,    26,
    29,    20,    21,    77,    26,    29,   106,   107,    20,    21,
   106,   107,    20,    21,   106,   107,    20,    21,   106,   107,
    20,    21,    53,    31,    51,    19,   134,    93,   137,   120,
    90,    15,   139,   140,   142,   143,   145,   146,   147 ]

racc_action_check = [
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,    60,    68,    68,    13,    68,    68,   133,    60,
    60,    71,    60,    60,   133,    63,    71,    71,    71,    71,
     4,    71,    71,   115,    44,     5,    44,     4,     4,   115,
     4,     4,     5,     5,     6,     5,     5,    17,    64,     7,
    17,     6,     6,    65,     6,     6,     7,     7,    84,     7,
     7,   102,   102,    89,    35,    84,    84,    32,    84,    84,
    89,    89,    90,    89,    89,    36,    70,   109,    27,    90,
    90,   109,    90,    90,    15,    73,    15,    40,    80,    82,
    15,    15,    31,    15,    15,    83,    31,    31,    24,    31,
    31,    11,    11,    57,    11,    11,   114,   114,    61,   114,
   114,    51,    51,    92,    51,    51,    34,    34,    10,    34,
    34,    67,    67,    99,    67,    67,    95,    95,   101,    95,
    95,    59,    59,    54,    59,    59,    41,    41,   103,    41,
    41,    33,    33,    33,    33,    33,    69,    69,    69,    69,
   131,   131,   131,   131,   125,   125,   125,   125,    74,    74,
    74,    74,     9,   113,     8,     3,   123,    53,   127,   129,
    46,     1,   135,   137,   140,   141,   142,   145,   146 ]

racc_action_pointer = [
    -2,   156,   nil,   152,    15,    20,    29,    34,   149,   162,
   103,    79,   nil,    -7,   nil,    68,   nil,    28,   nil,   nil,
   nil,   nil,   nil,   nil,    80,   nil,   nil,    54,   nil,   nil,
   nil,    74,    52,   119,    94,    50,    51,   nil,   nil,   nil,
    63,   114,   nil,   nil,    19,   nil,   156,   nil,   nil,   nil,
   nil,    89,   nil,   167,   118,   nil,   nil,    89,   nil,   109,
    -3,    94,   nil,     2,    30,    37,   nil,    99,    -9,   126,
    59,     6,   nil,    63,   138,   nil,   nil,   nil,   nil,   nil,
    64,   nil,    65,    71,    43,   nil,   nil,   nil,   nil,    48,
    57,   nil,    95,   nil,   nil,   104,   nil,   nil,   nil,   101,
   nil,   112,    39,   114,   nil,   nil,   nil,   nil,   nil,    63,
   nil,   nil,   nil,   148,    84,    15,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   147,   nil,   134,   nil,   145,   nil,   145,
   nil,   130,   nil,     0,   nil,   156,   nil,   150,   nil,   nil,
   157,   153,   153,   nil,   nil,   160,   155,   nil ]

racc_action_default = [
   -93,   -93,   -81,   -93,   -16,   -93,   -21,   -21,   -93,   -93,
   -93,   -42,   -73,   -88,   -79,   -93,   -10,   -93,   -11,   -12,
   -59,   -60,   -46,   -25,   -44,   -26,   -68,   -45,   -27,   -69,
   -49,   -93,   -93,   -93,   -93,   -13,   -57,   -14,    -1,   -17,
   -58,   -39,    -2,   -24,   -93,   -23,   -18,   -19,    -3,   -22,
    -4,   -93,    -5,   -93,    -6,   -70,   -40,    -7,   -44,   -43,
    -8,   -93,    -9,   -93,   -93,   -93,   -78,   -93,   -93,   -93,
   -36,   -93,   -82,   -88,   -93,   -65,   -28,   -64,   -50,   -57,
   -58,   -51,   -57,   -58,   -16,   -66,   -61,   -47,   -58,   -16,
   -21,   -76,   -93,   148,   -71,   -42,   -74,   -75,   -89,   -93,
   -31,   -93,   -93,   -52,   -54,   -34,   -55,   -56,   -33,   -93,
   -85,   -83,   -29,   -84,   -93,   -52,   -86,   -80,   -48,   -62,
   -67,   -63,   -15,   -93,   -20,   -93,   -41,   -93,   -32,   -53,
   -37,   -93,   -30,   -53,   -38,   -93,   -77,   -93,   -35,   -72,
   -93,   -93,   -93,   -92,   -87,   -90,   -93,   -91 ]

racc_goto_table = [
    14,    38,    62,    79,    82,    42,    45,    45,    59,    56,
     9,    79,    44,    44,    58,   109,    80,    83,    64,    78,
    81,   102,    65,   114,    88,   113,   102,    87,   124,    79,
    52,    76,    55,    96,    64,    48,    50,    79,    65,   103,
   122,   115,    88,    76,   103,    87,   105,    18,   116,    16,
    80,   118,    60,    78,    91,    57,    54,    92,   135,    17,
    72,   111,   117,    58,   141,   144,   nil,   nil,   nil,    67,
   112,    64,   129,   nil,    64,   101,    94,   102,   110,   nil,
   nil,   nil,    97,   102,   133,    67,   123,   nil,   nil,   nil,
    45,   nil,    59,   126,   nil,   103,    44,    83,    58,   nil,
    81,   103,   136,   nil,   nil,    67,   nil,   nil,   138,   nil,
   nil,   nil,   132,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    67,   nil,   nil,    67 ]

racc_goto_check = [
    20,     2,     9,    35,    35,     3,     3,     3,    27,    28,
     1,    35,    21,    21,    30,    26,    37,    37,    30,    32,
    32,    34,    19,    34,    37,    22,    34,    32,    15,    35,
     5,    20,     5,    29,    30,     4,     4,    35,    19,    35,
    13,    35,    37,    20,    35,    32,    25,    11,    25,    10,
    37,    25,     8,    32,    30,     7,     6,    38,    39,    40,
    41,    42,     9,    30,    44,    45,   nil,   nil,   nil,    33,
    20,    30,    35,   nil,    30,    19,     5,    34,    19,   nil,
   nil,   nil,     5,    34,    35,    33,     2,   nil,   nil,   nil,
     3,   nil,    27,    28,   nil,    35,    21,    37,    30,   nil,
    32,    35,    25,   nil,   nil,    33,   nil,   nil,    25,   nil,
   nil,   nil,    20,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    33,   nil,   nil,    33 ]

racc_goto_pointer = [
   nil,    10,    -3,     0,    29,    22,    46,    44,    40,   -11,
    48,    45,   nil,   -44,   nil,   -62,   nil,   nil,   nil,     7,
    -1,     6,   -46,   nil,   nil,   -23,   -55,    -3,    -2,   -27,
     3,   nil,   -14,    54,   -48,   -30,   nil,   -17,     6,   -67,
    57,    43,   -10,   nil,   -73,   -76 ]

racc_goto_default = [
   nil,   nil,   nil,    39,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    35,    37,    46,    47,    49,    43,    23,    25,
    28,    32,   nil,    68,    70,   nil,   nil,    41,   nil,    22,
    24,    27,    30,    33,    34,    36,   104,    40,   nil,   nil,
   nil,   nil,   nil,    63,   nil,   nil ]

racc_token_table = {
 false => 0,
 Object.new => 1,
 :MAILBOX_LIST => 2,
 :MAILBOX => 3,
 :ADDRESS_LIST => 4,
 :ADDRESS_LIST_BCC => 5,
 :MSG_ID => 6,
 :MSG_ID_LIST => 7,
 :PHRASE_LIST => 8,
 :PHRASE_MSG_ID_LIST => 9,
 :DATE_TIME => 10,
 :RETURN_PATH => 11,
 :RECEIVED => 12,
 :UNSTRUCTURED => 13,
 "," => 14,
 "<" => 15,
 ">" => 16,
 ":" => 17,
 "@" => 18,
 ";" => 19,
 :DOMAIN_LITERAL => 20,
 :NO_FOLD_LITERAL => 21,
 :ATOM => 22,
 :DIGIT => 23,
 "." => 24,
 :QUOTED_STRING => 25,
 :NO_FOLD_QUOTE => 26 }

racc_use_result_var = false

racc_nt_base = 27

Racc_arg = [
 racc_action_table,
 racc_action_check,
 racc_action_default,
 racc_action_pointer,
 racc_goto_table,
 racc_goto_check,
 racc_goto_default,
 racc_goto_pointer,
 racc_nt_base,
 racc_reduce_table,
 racc_token_table,
 racc_shift_n,
 racc_reduce_n,
 racc_use_result_var ]

Racc_token_to_s_table = [
'$end',
'error',
'MAILBOX_LIST',
'MAILBOX',
'ADDRESS_LIST',
'ADDRESS_LIST_BCC',
'MSG_ID',
'MSG_ID_LIST',
'PHRASE_LIST',
'PHRASE_MSG_ID_LIST',
'DATE_TIME',
'RETURN_PATH',
'RECEIVED',
'UNSTRUCTURED',
'","',
'"<"',
'">"',
'":"',
'"@"',
'";"',
'DOMAIN_LITERAL',
'NO_FOLD_LITERAL',
'ATOM',
'DIGIT',
'"."',
'QUOTED_STRING',
'NO_FOLD_QUOTE',
'$start',
'all',
'mailbox_list',
'mailbox',
'address_list',
'msg_id',
'msg_id_list',
'phrase_list',
'phrase_msg_id_list',
'date_time',
'return_path',
'received',
'mailbox_list_',
'mailbox_opt',
'address_list_',
'address_opt',
'address',
'group',
'name_addr',
'addr_spec',
'angle_addr',
'display_name',
'angle_addr_list',
'obs_route',
'obs_domain_list',
'domain',
'obs_domain_list_delim',
'phrase',
'phrase_opt',
'phrase0',
'local_part',
'word_dot_list_dot',
'word',
'word_dot_list',
'atom_dot_list',
'atom',
'domain_literal',
'quoted_string',
'id_left',
'id_right',
'name_val_list',
'name_val_pair',
'item_value',
'day_of_week',
'time_of_day',
'zone']

Racc_debug_parser = false

##### racc system variables end #####

 # reduce 0 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 12
  def _reduce_1( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 13
  def _reduce_2( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 14
  def _reduce_3( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 15
  def _reduce_4( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 16
  def _reduce_5( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 17
  def _reduce_6( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 18
  def _reduce_7( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 19
  def _reduce_8( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 20
  def _reduce_9( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 21
  def _reduce_10( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 22
  def _reduce_11( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 23
  def _reduce_12( val, _values)
val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 32
  def _reduce_13( val, _values)
                    unless val[0].empty? then
                      val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-1], nil))
                    end
                    val[0]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 37
  def _reduce_14( val, _values)
                    val[0] ? [val[0]] : []
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 44
  def _reduce_15( val, _values)
                    @comma_list << val[1].object_id
                    val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-2], @comma_list[-1]))
                    val[0] << val[2] if val[2]
                    val[0]
  end
.,.,

 # reduce 16 omitted

 # reduce 17 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 55
  def _reduce_18( val, _values)
                    if not val[0].empty? and val[0].last.kind_of? Mailbox then
                      val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-1], nil))
                    end
                    val[0]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 60
  def _reduce_19( val, _values)
                    val[0] ? [val[0]] : []
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 69
  def _reduce_20( val, _values)
                    @comma_list << val[1].object_id
                    if val[0].last.kind_of? Mailbox then
                      val[0].last.comments = decode2(@scanner.get_comment_by_id(@comma_list[-2], @comma_list[-1]))
                    end
                    val[0] << val[2] if val[2]
                    val[0]
  end
.,.,

 # reduce 21 omitted

 # reduce 22 omitted

 # reduce 23 omitted

 # reduce 24 omitted

 # reduce 25 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 81
  def _reduce_26( val, _values)
                    Mailbox.new(val[0])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 86
  def _reduce_27( val, _values)
                    Mailbox.new(val[0])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 90
  def _reduce_28( val, _values)
                    Mailbox.new(val[1], val[0])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 95
  def _reduce_29( val, _values)
                    [val[0]]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 100
  def _reduce_30( val, _values)
                    val[0] << val[1]
                    val[0]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 105
  def _reduce_31( val, _values)
                    val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 109
  def _reduce_32( val, _values)
                    val[2]
  end
.,.,

 # reduce 33 omitted

 # reduce 34 omitted

 # reduce 35 omitted

 # reduce 36 omitted

 # reduce 37 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 123
  def _reduce_38( val, _values)
                    Group.new(val[2], val[0])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 128
  def _reduce_39( val, _values)
                    decode(val[0])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 133
  def _reduce_40( val, _values)
                    [val[0]]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 138
  def _reduce_41( val, _values)
                    val[0] << val[2] if val[2]
                    val[0]
  end
.,.,

 # reduce 42 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 144
  def _reduce_43( val, _values)
                    decode(val[0])
  end
.,.,

 # reduce 44 omitted

 # reduce 45 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 152
  def _reduce_46( val, _values)
                    val[0].to_s
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 156
  def _reduce_47( val, _values)
                    val[0] << " #{val[1]}"
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 161
  def _reduce_48( val, _values)
                    AddrSpec.new(val[0], val[2])
  end
.,.,

 # reduce 49 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 167
  def _reduce_50( val, _values)
                    val.join
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 171
  def _reduce_51( val, _values)
                    val.join
  end
.,.,

 # reduce 52 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 177
  def _reduce_53( val, _values)
                    val.join
  end
.,.,

 # reduce 54 omitted

 # reduce 55 omitted

 # reduce 56 omitted

 # reduce 57 omitted

 # reduce 58 omitted

 # reduce 59 omitted

 # reduce 60 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 192
  def _reduce_61( val, _values)
                    val.join
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 196
  def _reduce_62( val, _values)
                    val[0] << val[1]+val[2]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 200
  def _reduce_63( val, _values)
                    val[0] << val[1]+val[2]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 205
  def _reduce_64( val, _values)
                    val.join
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 209
  def _reduce_65( val, _values)
                    val.join
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 214
  def _reduce_66( val, _values)
                    val.join
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 218
  def _reduce_67( val, _values)
                    val.join
  end
.,.,

 # reduce 68 omitted

 # reduce 69 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 226
  def _reduce_70( val, _values)
                    MsgIdList.new(val[0])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 230
  def _reduce_71( val, _values)
                    val[0] << val[1]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 235
  def _reduce_72( val, _values)
                    MsgId.new(val[1,3].join)
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 240
  def _reduce_73( val, _values)
                    MsgIdList.new()
  end
.,.,

 # reduce 74 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 245
  def _reduce_75( val, _values)
                    val[0] << val[1]
  end
.,.,

 # reduce 76 omitted

 # reduce 77 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 258
  def _reduce_78( val, _values)
                    nil
  end
.,.,

 # reduce 79 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 265
  def _reduce_80( val, _values)
                    Received.new(val[0], val[2])
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 270
  def _reduce_81( val, _values)
                    {}
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 275
  def _reduce_82( val, _values)
                    val[0][val[1][0]] = val[1][1]
                    val[0]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 283
  def _reduce_83( val, _values)
                    unless val[0] =~ /\A[a-zA-Z0-9](-?[a-zA-Z0-9])*\z/ then
                      raise MailParser::ParseError, val[0]+@scanner.rest
                    end
                    [val[0].downcase, val[1].to_s]
  end
.,.,

 # reduce 84 omitted

 # reduce 85 omitted

 # reduce 86 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 299
  def _reduce_87( val, _values)
                    year, month, day, time, zone = val.values_at(3,2,1,4,5)
                    raise MailParser::ParseError, year unless year =~ /\A\d\d\d\d\Z/
                    m = [nil,"jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"].index month.downcase
                    raise MailParser::ParseError, month if m.nil?
                    raise MailParser::ParseError, day unless day =~ /\A\d?\d\Z/
                    DateTime.new(year, m, day, time[0], time[1], time[2], zone)
  end
.,.,

 # reduce 88 omitted

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 307
  def _reduce_89( val, _values)
                    unless ['mon','tue','wed','thu','fri','sat','sun'].include? val[0].downcase then
                      raise MailParser::ParseError, val[0]
                    end
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 318
  def _reduce_90( val, _values)
                    if val[0] !~ /\A\d\d\Z/ or val[0].to_i > 23 then
                      raise MailParser::ParseError, val[0]
                    end
                    if val[2] !~ /\A\d\d\Z/ or val[2].to_i > 60 then
                      raise MailParser::ParseError, val[2]
                    end
                    [val[0].to_i, val[2].to_i, 0]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 331
  def _reduce_91( val, _values)
                    if val[0] !~ /\A\d\d\Z/ or val[0].to_i > 23 then
                      raise MailParser::ParseError, val[0]
                    end
                    if val[2] !~ /\A\d\d\Z/ or val[2].to_i > 59 then
                      raise MailParser::ParseError, val[2]
                    end
                    if val[4] !~ /\A\d\d\Z/ or val[4].to_i > 60 then
                      raise MailParser::ParseError, val[4]
                    end
                    [val[0].to_i, val[2].to_i, val[4].to_i]
  end
.,.,

module_eval <<'.,.,', 'lib/mailparser/rfc2822/parser.y', 340
  def _reduce_92( val, _values)
                    if val[0] =~ /\A[+-]\d\d\d\d\Z/ then
                      val[0]
                    else
                      ZONE[val[0].upcase] || "-0000"
                    end
  end
.,.,

 def _reduce_none( val, _values)
  val[0]
 end

    end   # class Parser

  end   # module RFC2822

end   # module MailParser
