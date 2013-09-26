#!/usr/bin/env ruby

# Usage: GITHUB_API_TOKEN=cafebabedeadbeef GITHUB_USER=username GITHUB_REPO=reponame ./pr-check.rb
require 'json'
require 'open-uri'
require 'pp'

TOKEN = ENV['GITHUB_API_TOKEN']
USER  = ENV['GITHUB_USER'] || "rapid7"
REPO  = ENV['GITHUB_REPO'] || "metasploit-framework"

def open_pull_requests
  numbers = []
  specs = []
  libs = []
  idx = 1
  more = true
  while more
    uri = open( "https://api.github.com/repos/#{USER}/#{REPO}/pulls?access_token=#{TOKEN}&state=open&page=#{idx}")
    doc = uri.read
    uri.close
    json_doc = JSON.parse(doc)
    idx += 1
    more = (json_doc.size > 0)
    next unless more
    puts "Fetched #{json_doc.size} PRs"
    json_doc.each do |pr|
      numbers << pr["number"].to_i
      # patches << pr["patch"]
      this_pr_files = get_patch_files(pr["patch_url"])
      if (this_pr_files.select {|f| f =~ /^lib/}).size > 0
        libs << pr["number"].to_i
        puts "Has lib: #{pr["number"]}"
      end
      if (this_pr_files.select {|f| f =~ /^spec/}).size > 0
        specs << pr["number"].to_i
        puts "Has spec: #{pr["number"]}"
      end
    end
    $stdout.flush
  end
  puts "Total: #{numbers.size}"
  numbers.sort.map do |pr|
    is_spec = specs.include? pr
    is_lib = libs.include? pr
    "#{pr} #{is_spec ? "S" : ""}#{is_lib ? "L" : ""}"
  end
end

def get_patch_files(uri)
  files = []
  in_files = false
  begin
  doc = open(uri)
  rescue
    puts "Could not open #{uri.split("/").last}"
    return files
  end
  doc.each_line do |line|
    in_files = !in_files if (line =~ /^---$/ or line =~ / [0-9]+ file/)
    next unless in_files
    files << line.strip
  end
  files
end

puts open_pull_requests.join("\n")
