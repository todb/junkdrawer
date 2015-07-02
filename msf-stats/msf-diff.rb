#!/usr/bin/env ruby

diff_dir = File.dirname(File.expand_path(__FILE__))

f = {
	:diffs => File.join(diff_dir,"details.diff"),
	:summs => File.join(diff_dir,"summary.txt"),
	:names => File.join(diff_dir,"names.txt")
}

f.each_pair do |k,v|
	puts v.inspect
end
tags = %x{git tag | grep blog- }.split(/\n/)
last_tag    = ARGV[0] || tags.last
next_branch = ARGV[1] || "HEAD"

puts "Comparing last tag: #{last_tag} with branch '#{next_branch}'" 
%x{git diff -b --name-only #{last_tag}..#{next_branch} > #{f[:names]}}
%x{git diff -b --summary #{last_tag}..#{next_branch} > #{f[:summs]}}
%x{git diff -b #{last_tag}..#{next_branch} > #{f[:diffs]}}
puts "Done, to edit modules:"
puts ""
fh = File.open(f[:summs]) {|f| f.read f.stat.size}
mods = []
fh.each_line do |line|
	next unless line =~ /create mode.*modules/
	mods << line.split.last.strip
end
puts "gvim #{mods.join " "}"
