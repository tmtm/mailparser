#
# $Id$
#
# Copyright (C) 2006 TOMITA Masahiro
# mailto:tommy@tmtm.org

module RFC2231
  class ParseError < StandardError
  end

  module_function
  def parse_param(params)
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
          raise ParseError, "#{key}=#{value}"
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
    newparams.each do |k, v|
      class << v
        attr_accessor :charset, :language
      end
      v.charset, v.language = char_lang[k] if char_lang.key? k
    end
    return newparams
  end
end
