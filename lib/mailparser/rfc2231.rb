# Copyright (C) 2006-2010 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "mailparser/error"

module MailParser::RFC2231
  module_function
  def parse_param(params, opt={:strict=>true})
    opt = {:strict=>opt} unless opt.is_a? Hash
    newparams = {}
    h = Hash.new{|h,k| h[k] = []}
    char_lang = {}
    params.each do |key, value|
      case key
      when /^([^\*]+)(\*0)?\*$/no
        name, ord = $1, $2
        char, lang, v = value.split(/\'/, 3)
        char_lang[name] = [char, lang]
        if v.nil? then
          raise MailParser::ParseError, "#{key}=#{value}" if opt[:strict]
          v = lang || char
        end
        v = v.gsub(/%([0-9A-F][0-9A-F])/ni){$1.hex.chr}
        if ord then
          h[name] << [0, v]
        else
          newparams[name] = v
        end
      when /^([^\*]+)\*([1-9]\d*)\*$/no
        name, ord = $1, $2.to_i
        v = value.gsub(/%([0-9A-F][0-9A-F])/ni){$1.hex.chr}
        h[name] << [ord, v]
      when /^([^\*]+)\*([0-9]\d*)$/no
        name, ord = $1, $2.to_i
        h[name] << [ord, value]
      else
        newparams[key] = value
      end
    end
    h.each do |k, v|
      newparams[k] = v.sort{|a,b| a[0]<=>b[0]}.map{|a| a[1]}.join
    end
    newparams.keys.each do |k|
      v = newparams[k]
      if char_lang.key? k and opt[:output_charset]
        charset_converter = opt[:charset_converter] || Proc.new{|f,t,s| ConvCharset.conv_charset(f,t,s)}
        v.replace charset_converter.call(char_lang[k][0], opt[:output_charset], v) rescue nil
      end
      class << v
        attr_accessor :charset, :language
      end
      v.charset, v.language = char_lang[k] if char_lang.key? k
      newparams[k] = v
    end
    return newparams
  end
end
