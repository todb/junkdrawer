#!/usr/bin/env ruby

require 'json'
require 'open-uri'

def open_pull_requests
  numbers = []
  idx = 1
  more = true
  while more
    uri = open( "https://api.github.com/repos/rapid7/metasploit-framework/pulls?state=open&page=#{idx}")
    doc = uri.read
    uri.close
    json_doc = JSON.parse(doc)
    idx += 1
    more = (json_doc.size > 0)
    next unless more
    puts "Fetched #{json_doc.size} PRs"
    json_doc.each do |pr|
      numbers << pr["number"].to_i
    end
  end
  puts "Total: #{numbers.size}"
  numbers.sort
end

puts open_pull_requests.join(" ")
