# coding: ascii-8bit
# Copyright (C) 2007-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "time"
require "strscan"
require "mailparser/rfc2822"
require "mailparser/rfc2045"
require "mailparser/rfc2047"
require "mailparser/rfc2183"

module MailParser
  module Loose
    HEADER_PARSER = {
      "date"                      => :parse_date,
      "from"                      => :parse_mailbox_list,
      "sender"                    => :parse_mailbox,
      "reply-to"                  => :parse_mailbox_list,
      "to"                        => :parse_mailbox_list,
      "cc"                        => :parse_mailbox_list,
      "bcc"                       => :parse_mailbox_list,
      "message-id"                => :parse_msg_id,
      "in-reply-to"               => :parse_msg_id_list,
      "references"                => :parse_msg_id_list,
      "keywords"                  => :parse_phrase_list,
      "resent-date"               => :parse_date,
      "resent-from"               => :parse_mailbox_list,
      "resent-sender"             => :parse_mailbox,
      "resent-to"                 => :parse_mailbox_list,
      "resent-cc"                 => :parse_mailbox_list,
      "resent-bcc"                => :parse_mailbox_list,
      "resent-message-id"         => :parse_msg_id,
      "return-path"               => :parse_return_path,
      "received"                  => :parse_received,
      "content-type"              => :parse_content_type,
      "content-transfer-encoding" => :parse_content_transfer_encoding,
      "content-id"                => :parse_msg_id,
      "mime-version"              => :parse_mime_version,
      "content-disposition"       => :parse_content_disposition,
    }

    module_function
    # @param [String] hname
    # @param [String] hbody
    # @param [Hash] opt options
    # @return [header field value]
    def parse(hname, hbody, opt={})
      if HEADER_PARSER.key? hname then
        return method(HEADER_PARSER[hname]).call(hbody, opt)
      else
        r = hbody.gsub(/\s+/, " ")
        if opt[:decode_mime_header] then
          return RFC2047.decode(r, opt)
        else
          return r
        end
      end
    end

    # parse Date field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2822::DateTime]
    def parse_date(str, opt={})
      begin
        t = Time.rfc2822(str) rescue Time.parse(str)
      rescue
        t = Time.now
      end
      year = t.year > 9999 ? 9999 : t.year
      return RFC2822::DateTime.new(year, t.month, t.day, t.hour, t.min, t.sec, t.zone)
    end

    # parse From, To,Cc field
    # @param [String] str
    # @param [Hash] opt options
    # @return [Array<MailParser::RFC2822::Mailbox>]
    def parse_mailbox_list(str, opt={})
      mailbox_list(str, opt)
    end

    # parse Sender,Resent-Sender field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2822::Mailbox]
    def parse_mailbox(str, opt={})
      mailbox_list(str, opt)[0]
    end

    # parse Message-Id, Resent-Message-Id field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2822::MsgId]
    def parse_msg_id(str, opt={})
      msg_id_list(str, opt)[0]
    end

    # parse In-Reply-To, References field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2822::MsgIdList]
    def parse_msg_id_list(str, opt={})
      msg_id_list(str, opt)
    end

    # parse Keywords field
    # @param [String] str
    # @param [Hash] opt options
    # @return [Array<String>]
    def parse_phrase_list(str, opt={})
      s = split_by(Tokenizer.token(str), ",")
      s.map!{|i| i.join(" ")}
      if opt[:decode_mime_header] then
        s.map!{|i| RFC2047.decode(i, opt)}
      end
      s.map{|_| _conv(_, opt)}
    end

    # parse Return-Path field
    # @param [String] str
    # @param [Hash] opt options
    # @return [Array<MailParser::RFC2822::ReturnPath>]
    def parse_return_path(str, opt={})
      mailbox_list(str, opt)[0]
    end

    # parse Received field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2822::Received]
    def parse_received(str, opt={})
      a = split_by(Tokenizer.token_received(str), ";")
      date = a.length > 1 ? parse_date(a.last.join(" ")) : RFC2822::DateTime.now
      name_val = {}
      i = 0
      v = ""
      unless a.empty?
        while i < a[0].length do
          if a[0][i] =~ /\A[a-z0-9]+\z/i then
            v = a[0][i+1]
            name_val[a[0][i].downcase] = v
            i += 1
          else
            v << a[0][i]
          end
          i += 1
        end
      end
      name_val.keys.each do |k|
        name_val[k] = _conv(name_val[k], opt)
      end
      RFC2822::Received.new(name_val, date)
    end

    # parse Content-Type field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2045::ContentType]
    def parse_content_type(str, opt={})
      token = split_by(Tokenizer.token(str), ";")
      type, subtype = token.empty? ? nil : token.shift.join.split("/", 2)
      params = {}
      token.each do |param|
        pn, pv = param.join.split(/=/, 2)
        params[pn.to_s] = _conv(pv.to_s.gsub(/\A"|"\z/,""), opt)
      end
      type = "text" if type.nil? or type.empty?
      if subtype.nil? or subtype.empty?
        subtype = type == "text" ? "plain" : ""
      end
      RFC2045::ContentType.new(_conv(type, opt), _conv(subtype, opt), params)
    end

    # parse Content-Transfer-Encoding field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2045::ContentTransferEncoding]
    def parse_content_transfer_encoding(str, opt={})
      RFC2045::ContentTransferEncoding.new(_conv(Tokenizer.token(str).first.to_s, opt))
    end

    # parse Mime-Version field
    # @param [String] str
    # @param [Hash] opt options
    # @return [String]
    def parse_mime_version(str, opt={})
      _conv(Tokenizer.token(str).join, opt)
    end

    # parse Content-Disposition field
    # @param [String] str
    # @param [Hash] opt options
    # @return [MailParser::RFC2183::ContentDispositoin]
    def parse_content_disposition(str, opt={})
      token = split_by(Tokenizer.token(str), ";")
      type = token.empty? ? '' : token.shift.join
      params = {}
      token.each do |param|
        pn, pv = param.join.split(/=/, 2)
        params[pn.to_s] = _conv(pv.to_s.gsub(/\A"|"\z/,""), opt)
      end
      RFC2183::ContentDisposition.new(_conv(type, opt), params)
    end

    # split arry by delim
    # @param [Array] array
    # @param [Object] delim
    # @return [Array<Array>]
    def split_by(array, delim)
      ret = []
      a = []
      array.each do |i|
        if i == delim then
          ret << a
          a = []
        else
          a << i
        end
      end
      ret << a unless a.empty?
      return ret
    end

    # parse Mailbox type field
    # @param [String] str
    # @param [Hash] opt options
    # @return [Array<MailParser::RFC2822::Mailbox>]
    def mailbox_list(str, opt)
      ret = []
      split_by(Tokenizer.token(str), ",").each do |m|
        if a1 = m.index("<") and a2 = m.rindex(">") and a2 > a1 then
          display_name = m[0..a1-1].join(" ")
          if opt[:decode_mime_header] then
            display_name = RFC2047.decode(display_name, opt)
          end
          mailaddr = _conv(m[a1+1..a2-1].join, opt)
          local_part, domain = mailaddr.split(/@/, 2)
          ret << RFC2822::Mailbox.new(RFC2822::AddrSpec.new(local_part, domain), _conv(display_name, opt))
        else
          local_part, domain = _conv(m.join, opt).split(/@/, 2)
          ret << RFC2822::Mailbox.new(RFC2822::AddrSpec.new(local_part, domain))
        end
      end
      return ret
    end

    # parse MsgId type field
    # @param [String] str
    # @return [Array<MailParser::RFC2822::MsgId>]
    def msg_id_list(str, opt={})
      ret = []
      flag = false
      msgid = nil
      Tokenizer.token(str).each do |m|
        case m
        when "<"
          unless flag
            flag = true
            msgid = ""
          end
        when ">"
          if flag
            flag = false
            ret << RFC2822::MsgId.new(_conv(msgid, opt))
          end
        else
          msgid << m if flag
        end
      end
      if ret.empty?
        ret = str.split.map{|s| RFC2822::MsgId.new(_conv(s, opt))}
      end
      return ret
    end

    class Tokenizer < RFC2822::Scanner
      # @return [String] str source string
      def initialize(str)
        @comments = []
        @ss = StringScanner.new(str)
      end

      # tokenize
      # @return [Array<String>] tokens
      def token()
        token = []
        while @ss.rest? do
          if s = @ss.scan(/\s+/) then
            # ignore
          elsif s = @ss.scan(/\(/) then
            begin
              pos = @ss.pos
              cfws(@ss)
            rescue ParseError
              @ss.pos = pos
              token << s
            end
          elsif s = @ss.scan(/\"(\s*(\\[#{TEXT_RE}]|[#{QTEXT_RE}\x80-\xff]))*\s*\"/o) ||
              @ss.scan(/\[(\s*(\\[#{TEXT_RE}]|[#{DTEXT_RE}\x80-\xff]))*\s*\]/o) ||
              @ss.scan(/[#{ATEXT_RE}\x80-\xff]+/o)
            token << s
          else
            token << @ss.scan(/./)
          end
        end
        return token
      end

      # tokenize for Received field
      # @return [Array<String>] tokens
      def token_received()
        ret = []
        while @ss.rest? do
          if s = @ss.scan(/[\s]+/) then
            # ignore blank
          elsif s = @ss.scan(/\(/) then
            begin
              pos = @ss.pos
              cfws(@ss)
            rescue ParseError
              @ss.pos = pos
              ret.last << s unless ret.empty?
            end
          elsif s = @ss.scan(/\"([\s]*(\\[#{TEXT_RE}]|[#{QTEXT_RE}]))*[\s]*\"/o)
            ret << s
          elsif s = @ss.scan(/;/)
            ret << s
          else
            ret << @ss.scan(/[^\s\(\;]+/o)
          end
        end
        return ret
      end

      def self.token(str)
        Tokenizer.new(str).token
      end

      def self.token_received(str)
        Tokenizer.new(str).token_received
      end
    end

    def _conv(str, opt)
      cv = opt[:charset_converter]
      cs = opt[:output_charset]
      cv && cs ? cv.call(cs, cs, str) : str
    end

  end
end
