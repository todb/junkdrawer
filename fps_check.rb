#!/usr/bin/env ruby

require 'open3'
require 'socket'
require 'terminator'

arg = ARGV[0]
if arg
  if File.readable? arg
    data = File.open(arg, "rb") {|f| f.read f.stat.size}
    hosts = data.split("\n")
    hosts.map! {|t| t.strip}
    hosts.reject! {|t| t =~ /(^#)|(^[\s\t]*$)/}
    hosts.compact!
  else
    hosts = [arg.strip]
  end
else
  hosts = ["mail.google.com"]
end

results = []

def check_cipher(target)
  cmd = %W{openssl s_client -connect #{target}}
  cipher = nil
  Open3.popen3(*cmd) {|stdin, stdout, sterr, thread|
    stdin.puts "just checking"
    cipher = stdout.select {|x| x =~ /Cipher    :/}.first
  }
  return cipher
end

def check_resolv(target)
  host,port = target.split(":")
  resolved = Socket.gethostbyname(host).first rescue nil
end

hosts.each do |host|
  target = host.strip
  target << ":443" unless target =~ /:/
  tries = 0
  cipher = nil
  while tries <= 3
    if tries != 3
      begin
        Terminator.terminate 3 do
          resolved = check_resolv(host)
          unless resolved
            puts "%-40s %s" % [target, "TIMEOUT-HOST"]
            tries = 100
            next
          end
          cipher = check_cipher(target)
          if cipher and cipher.size > 0
            cipher = cipher.split(":").last.strip
          else
            cipher = "NONE"
          end
          results << [target, cipher]
          puts "%-40s %s" % [target, cipher]
          tries = 100
        end
      rescue Terminator::Error
        tries += 1
      end
    else
      puts "%-40s %s" % [target, "TIMEOUT-PORT"]
      tries = 100
      next
    end
  end
end

