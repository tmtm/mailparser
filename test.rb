# Copyright (C) 2007-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser"

unless ARGV.empty?
  ARGV.each do |fname|
    rawh = nil
    begin
      File.open(fname) do |f|
puts fname
        m = MailParser::Message.new(f, :decode_mime_header=>true, :output_charset=>"UTF-8")
        m.header.keys.each do |k| rawh = "#{k}: #{m.header.raw(k)}"; m.header[k] end
        m.body
      end
    rescue MailParser::ParseError => e
      puts fname
      puts rawh
      p e
    end
  end
  exit
end

require "test/unit"
Test::Unit::AutoRunner.run(true, "test")
