#!/usr/bin/env ruby

# Usage: Run in the metaploit-framework repo (or really any repo) to get
# a list of committers, sorted by total commits and alphabetically

first_commit = ARGV[0] || "65977c9" # Commit from Dec 31, 2014, about 10am
last_commit =  ARGV[1] || "d1ceda3" # Commit from Dec 31, 2015, about 10am

data = %x{git log --format="%aN" #{first_commit}...#{last_commit} | sort | uniq -c }
committers = {}

data.each_line do |line|
  fixed = line.lstrip.chomp
  commits, author = fixed.split(/\s/,2)
  committers[author] = commits.to_i
end

puts "Committers by commit count:"
sorted_by_count = committers.sort_by {|author, count| count}.reverse
puts sorted_by_count.map {|x| "#{x[0]} (#{x[1]})"}.join(', ')

puts ""

puts "Alphabetized committer list:"
puts committers.keys.sort_by {|author, count| author.downcase}.join(', ')
