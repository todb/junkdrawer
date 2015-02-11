#!/usr/bin/env ruby

infile = ARGV[0]
outfile = infile + ".out"
newfile = []
link = 'https://github.com/rapid7/metasploit-framework/pull/'

data = File.open(infile) {|f| f.read f.stat.size}
data.each_line do |line|
  if line =~ /(PR #(\d+)):/
    whole_pr = $1
    pr_num = $2
    newfile << line.gsub(whole_pr, "<a href='#{link}#{pr_num}'>#{whole_pr}</a>")
  else
    newfile << line
  end
end

File.open(outfile, "wb") {|f| f.write newfile.join}

