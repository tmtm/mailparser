MailParser
==========

MailParser is a parser for mail message.

Installation
------------

    % gem install --pre mailparser

Usage
-----

    require 'mailparser'
    f = File.open('hoge.eml')
    m = MailParser::Message.new(f, :output_charset=>'utf-8')
    m.subject  #=> String
    m.body     #=> String
    m.part     #=> Array of Mailparser::Message

License
-------

Ruby's


Copyright
---------

Copyright (C) 2009 TOMITA Masahiro <tommy@tmtm.org>
