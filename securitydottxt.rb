#!/usr/bin/env ruby

require 'uri'

SECPART = '/.well-known/security.txt'

infile = ARGV[0]

exit unless infile

data = File.open(infile, "r") {|f| f.read f.stat.size}

data.split.each do |d|
  url = URI::join(d.strip, SECPART)
  puts "CHECKING: #{url}"
  res = %x{curl -L --silent --insecure #{url}}
    begin
      if res =~ /(^|\n)?(\s)*Contact: /i
      puts res.inspect
    else
      puts "[No security.txt found]"
    end
    rescue => error
      puts "[Error: #{error.message}]"
    end
  end
