#!/usr/bin/env ruby

# Create a usable html version of a list of PRs, as generated from
# the git alias:
#
#   rlsnotes = !"git nicelog $1...$2 | sed -r \"s:\\x1B\\[[0-9;]*[mK]::g\" | cut -f 2-99 -d '-' | sort -n | grep -i ' Land' | sed s:Land:PR:g #  #"
#
# In most cases, you're going to want to manually edit rlsnotes output
# anyway, but this should help with the final list for proper release
# note publishing

infile = ARGV[0]
data  = File.open(infile, 'rb') {|f| f.read}

data.each_line do |line|
  pr = line.match(/#([0-9]{4})/)[1] rescue nil
  next unless pr
  href = %Q{<a href="https://github.com/rapid7/metasploit-framework/pull/#{pr}">##{pr}</a>}
  puts line.gsub(/##{pr}/,href) + "<br/>"
end
