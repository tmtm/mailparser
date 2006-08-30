require "rfc2822"
ARGV.each do |fname|
  File.open(fname) do |f|
    header = []
    f.each do |line|
      break if line.chomp.empty?
      if line =~ /^\s/ then
        header[-1] << line
      else
        header << line
      end
    end
    header.each do |h|
      begin
        RFC2822.parse(*h.split(/\s*:\s*/, 2))
      rescue => e
        puts fname
        p e
        p h
      end
    end
  end
end
