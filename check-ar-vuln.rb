#!/usr/bin/env ruby

# See:
# https://gist.github.com/todb-r7/7e8d5b2595021adb441e

fname = ARGV[0] || "./db/schema.rb"
data = File.open(fname, "rb") {|f| f.read f.stat.size}
tables = {}
@this_table = nil
@columns = []
data.each_line do |line|
  if line =~ /^\s+create_table\s+([^,]+)/
    @this_table = $1
    print "Checking #{@this_table}: "
    next
  end
  if line =~ /^\s+end$/
    if @columns.include? @this_table
      puts "=== OHNO === Table includes column name!"
    end
    @this_table = nil
    puts "." * @columns.size
    @columns = []
  end

  if @this_table
    colname = line.split[1].split(",")[0]
    @columns << colname
  end

end
