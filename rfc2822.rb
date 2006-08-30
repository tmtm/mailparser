require "rfc2822/parser"

module RFC2822

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
    "in-reply-to"       => :MSG_ID_LIST,
    "references"        => :MSG_ID_LIST,
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

  class MailboxList < Array
    def initialize(val=nil)
      self << val if val
    end
  end

  class Mailbox
    def initialize(addr_spec, display_name)
      @addr_spec = addr_spec
      @display_name = display_name
    end
    attr_reader :addr_spec, :display_name
    alias :phrase :display_name
    def to_s
      if displayname then
        "#{@display_name} <#{@addr_spec}>"
      else
        @addrspec.to_s
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
  end

  class MsgId
    def initialize(msg_id)
      @msg_id = msg_id
    end
    attr_reader :msg_id
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

  module_function
  def parse(name, value)
    htype = HEADER_TYPE[name.downcase] || :UNSTRUCTURED
    parser = Parser.new
    parser.parse(htype, value)
  end

end
