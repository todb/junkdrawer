#!/usr/bin/env ruby
# aha-gcveify.rb - Turns CVE records into the AHA! GCVE format.
# @version 1.0.0
# @author Tod Beardsley <todb@hugesuccess.org>
# @license BSD 2-Clause

require 'json'
require 'uri'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} --read <file> [--output FILE] [--gcve] [--ndjson]"

  opts.on('-r', '--read FILE', 'Read a source CVE JSON file') do |file|
    options[:input] = file
  end

  opts.on('-o', '--output FILE', 'Write output to FILE') do |file|
    options[:output] = file
  end

  opts.on('-O', '--gcve', 'Write output to <GCVE-ID>.json') do
    options[:gcve] = true
  end

  opts.on('-n', '--ndjson', 'Write as NDJSON (one line)') do
    options[:ndjson] = true
  end
end.parse!

unless options[:input]
  warn 'No input file provided. Use --read <file>'
  exit 1
end

begin
  cve_data = JSON.parse(File.read(options[:input]))
rescue StandardError => e
  warn "Failed to read/parse JSON: #{e}"
  exit 1
end

cna = cve_data.dig('containers', 'cna')
adp = cve_data.dig('containers', 'adp')

begin
  gcve_ref = cna['references']&.find { |r| r['url'] =~ %r{https://takeonme\.org/gcves/(GCVE-\d+-\d+-\d+)} }
  raise 'No GCVE reference found.' unless gcve_ref

  gcve_id = gcve_ref['url'][%r{https://takeonme\.org/gcves/(GCVE-\d+-\d+-\d+)}, 1]
  raise 'Failed to parse GCVE ID.' unless gcve_id

  gcve_provider_id = gcve_id.split('-')[1].to_i
rescue StandardError => e
  warn e.message
  exit 1
end

description_entry = cna['descriptions']&.find { |d| d['value'] && !d['value'].empty? }
unless description_entry
  warn 'No description found.'
  exit 2
end
description = { 'lang' => description_entry['lang'], 'value' => description_entry['value'] }

# All the other fields are optional
credits = cna['credits']
title = cna['title']

cwe_ids = cna['problemTypes']&.flat_map do |pt|
  pt['descriptions']&.map { |d| d['cweId'] }&.compact
end&.compact
cwe_ids = cwe_ids.uniq.sort_by { |id| -id.split('-')[1].to_i } if cwe_ids

cvss = cna['metrics']&.map { |m| m['cvssV3_1'] }&.compact&.first

ssvc = nil
if adp
  adp.each do |provider|
    next unless provider.dig('providerMetadata', 'shortName') == 'CISA-ADP'
    ssvc_entry = provider['metrics']&.map { |m| m.dig('other', 'content') }&.compact&.first
    next unless ssvc_entry

    ssvc = {
      'id' => gcve_id,
      'timestamp' => ssvc_entry['timestamp'],
      'version' => ssvc_entry['version'],
      'selections' => ssvc_entry['options']&.map do |opt|
        {
          'name' => opt.keys.first,
          'value' => opt.values.first
        }
      end
    }
  end
end

# GCVE, assemble!
gcve_record = {
  'gcveId' => gcve_id,
  'gcveProviderId' => gcve_provider_id,
  'datePublic' => cna['datePublic'],
  'title' => title,
  'description' => description,
  'cweIds' => cwe_ids,
  'cvss' => cvss,
  'ssvc' => ssvc,
  'credits' => credits,
  'references' => cna['references'],
  'affected' => cna['affected'],
  'cveId' => cve_data.dig('cveMetadata', 'cveId')
}.compact

output_str = options[:ndjson] ? "#{gcve_record.to_json}\n" : JSON.pretty_generate(gcve_record)

# Determine output path
output_path = if options[:output]
                options[:output]
              elsif options[:gcve]
                "#{gcve_id}.json"
              end

if output_path
  File.write(output_path, output_str)
  puts "[*] Wrote to #{output_path}"
else
  puts output_str
end
