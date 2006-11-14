#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

class MailParser
end

require "mailparser/rfc2822/parser"

module MailParser::RFC2822
  class ParseError < StandardError
  end

  HEADER_TYPE = {
    "date"              => :DATE_TIME,
    "from"              => :MAILBOX_LIST,
    "sender"            => :MAILBOX,
    "reply-to"          => :ADDRESS_LIST,
    "to"                => :ADDRESS_LIST,
    "cc"                => :ADDRESS_LIST,
    "bcc"               => :ADDRESS_LIST_BCC,
    "message-id"        => :MSG_ID,
    "in-reply-to"       => :PHRASE_MSG_ID_LIST,
    "references"        => :PHRASE_MSG_ID_LIST,
    "subject"           => :UNSTRUCTURED,
    "comments"          => :UNSTRUCTURED,
    "keywords"          => :PHRASE_LIST,
    "resent-date"       => :DATE_TIME,
    "resent-from"       => :MAILBOX_LIST,
    "resent-sender"     => :MAILBOX,
    "resent-to"         => :ADDRESS_LIST,
    "resent-cc"         => :ADDRESS_LIST,
    "resent-bcc"        => :ADDRESS_LIST_BCC,
    "resent-message-id" => :MSG_ID,
    "return-path"       => :RETURN_PATH,
    "received"          => :RECEIVED,
  }
  
  ZONE = {
    "UT"  => "+0000",
    "GMT" => "+0000",
    "EDT" => "-0400",
    "EST" => "-0500",
    "CDT" => "-0500",
    "EDT" => "-0400",
    "EST" => "-0500",
    "CDT" => "-0500",
    "CST" => "-0600",
    "MDT" => "-0600",
    "MST" => "-0700",
    "PDT" => "-0700",
    "PST" => "-0800",
    "A"   => "+0100",
    "B"   => "+0200",
    "C"   => "+0300",
    "D"   => "+0400",
    "E"   => "+0500",
    "F"   => "+0600",
    "G"   => "+0700",
    "H"   => "+0800",
    "I"   => "+0900",
    "K"   => "+1000",
    "L"   => "+1100",
    "M"   => "+1200",
    "N"   => "-0100",
    "O"   => "-0200",
    "P"   => "-0300",
    "Q"   => "-0400",
    "R"   => "-0500",
    "S"   => "-0600",
    "T"   => "-0700",
    "U"   => "-0800",
    "V"   => "-0900",
    "W"   => "-1000",
    "X"   => "-1100",
    "Y"   => "-1200",
    "Z"   => "+0000",
    "JST" => "+0900",
  }

  class AddrSpec
    def initialize(local_part, domain)
      @local_part = local_part
      @domain = domain
    end
    attr_reader :local_part, :domain
    def to_s
      "#{@local_part}@#{@domain}"
    end
  end

  class Mailbox
    def initialize(addr_spec, display_name=nil)
      @addr_spec = addr_spec
      @display_name = display_name || ""
    end
    attr_reader :addr_spec, :display_name
    alias :phrase :display_name
    def to_s()
      if display_name.empty? then
        "<#{@addr_spec}>"
      else
        "#{@display_name} <#{@addr_spec}>"
      end
    end
  end

  class Group
    def initialize(mailbox_list, display_name)
      @mailbox_list = mailbox_list
      @display_name = display_name
    end
    attr_reader :mailbox_list, :display_name
    alias :phrase :display_name
    def to_s()
      "#{@display_name}:#{@mailbox_list.join(",")};"
    end
  end

  class ReturnPath
    def initialize(addr_spec=nil)
      @addr_spec = addr_spec
    end
    attr_reader :addr_spec
  end

  class MsgIdList < Array
    def initialize(val=nil)
      self << val if val
    end
    def to_s()
      self.map{|i| i.to_s}.join(" ")
    end
  end

  class MsgId
    def initialize(msg_id)
      @msg_id = msg_id
    end
    attr_reader :msg_id
    def to_s()
      "<#{@msg_id}>"
    end
  end

  class AddressList < Array
    def initialize(val=nil)
      self << val if val
    end
  end

  class PhraseList < Array
    def initialize(val=nil)
      self << val if val
    end
  end

  class DateTime
    def initialize(year, month, day, hour, min, sec, zone)
      unless zone =~ /^[+-]\d\d\d\d$/ then
        zone = ZONE[zone.upcase] || "-0000"
      end
      @year, @month, @day, @hour, @min, @sec, @zone =
        year.to_i, month.to_i, day.to_i, hour.to_i, min.to_i, sec.to_i, zone
      z = zone[1,4].to_i
      @zone_sec = z/100*3600 + z%100*60
      @zone_sec = -@zone_sec if zone[0] == ?-
    end

    attr_reader :year, :month, :day, :hour, :min, :sec, :zone

    def time()
      t = Time.utc(@year, @month, @day, @hour, @min, @sec)
      Time.at(t.to_i - @zone_sec)
    end
  end

  module_function

  def parse(name, value)
    htype = HEADER_TYPE[name.downcase] || :UNSTRUCTURED
    if htype == :UNSTRUCTURED then
      return value.chomp
    end
    if htype.is_a? Array then
      parser = htype[0]::Parser.new
      parser.parse(htype[1], value)
    else
      parser = Parser.new
      parser.parse(htype, value)
    end
  end
end
