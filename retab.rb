#!/usr/bin/env ruby
# -*- coding: binary -*-

# Replace leading tabs with 2-width spaces.
# I'm sure there's a sed/awk/perl oneliner that's
# a million times better but this is more readable for me.
# 
# Usage:
# metasploit-framework$ ./tools/dev/retab.rb [path]
#
# If local backups are desired, prepend with "MSF_RETAB_BACKUPS" set,
# like so:
# metasploit-framework$ MSF_RETAB_BACKUPS=1 ./tools/dev/retab.rb [path]

require 'fileutils'
require 'find'

dir = ARGV[0] || "."
keep_backups = !!(ENV['MSF_RETAB_BACKUPS'] || ENV['MSF_RETAB_BACKUP'])
puts "Keeping .notab backups" if keep_backups

raise ArgumentError, "Need a filename or directory" unless (dir and File.readable? dir)

def is_ruby?(fname)
  return true if fname =~ /\.rb$/
  file_util = ""
  begin
    file_util = %x{which file}.to_s.chomp
  rescue Errno::ENOENT
  end
  if File.executable? file_util
    file_fingerprint = %x{#{file_util} #{fname}}
    !!(file_fingerprint =~ /Ruby script/)
  end
end

Find.find(dir) do |infile|
  next if infile =~ /\.git[\x5c\x2f]/
  next unless File.file? infile
  next unless is_ruby? infile
  outfile = infile

  if keep_backups
    backup = "#{infile}.notab"
    FileUtils.cp infile, backup
  end

  data = File.open(infile, "rb") {|f| f.read f.stat.size}
  fixed = []
  data.each_line do |line|
    fixed << line
    next unless line =~ /^\x09/
    index = []
    i = 0
    line.each_char do |char|
      break unless char =~ /[\x20\x09]/
      index << i if char == "\x09"
      i += 1
    end
    index.reverse.each do |idx|
      line[idx] = "  "
    end
    fixed[-1] = line
  end

  fh = File.open(outfile, "wb")
  fh.write fixed.join
  fh.close
  puts "Retabbed #{fh.path}"
end
