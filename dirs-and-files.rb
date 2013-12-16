#!/usr/bin/env ruby

# Usage: dirs-and-files.rb [path]
# Finds directories that contain both files and subdirectories.

require 'find'

top_dir = ARGV[0] || "."

unless File.directory? top_dir
  raise ArgumentError, "#{top_dir} is not a directory."
end

dirs = Find.find(top_dir).select {|x| File.directory? x}
dirs.sort!
dirs.each do |this_dir|
  files = Dir.entries(this_dir).select {|x| File.file? File.join(this_dir,x) }
  nonfiles = Dir.entries(this_dir).reject {|x| File.file?(File.join(this_dir,x)) || x == "." || x == ".." }
  if (files.size > 0) && (nonfiles.size > 0)
    puts "#{this_dir} contains files and nonfiles."
  end
end

