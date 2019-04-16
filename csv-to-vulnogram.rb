#!/usr/bin/ruby

require 'csv'
# require 'json' # Turns out, no JSON objects are here, just strings.

# NOTE: This assumes one single affected version, which is
# usually the case. If there is a known range of versions,
# then you'll need to monkey with that in the output manually.

VERSION = "0.0.2"

infile_name = ARGV[0]
begin
  csv = CSV.read(infile_name, :headers => true)
rescue
  puts "Can't read #{infile_name}."
  exit 1
end

cve_data = []

csv.each do |line|
  next if line["PR of JSON"] # Already submitted
  next unless line["Reserve CVE"]
  new_cve = {
    :cve_id => line["Reserve CVE"],
    :product_name => line["Product Name"],
    :version_value => line["Product Version"],
    :misc_ref => line["MISC Link"],
    :vendor_name => line["Vendor Name"],
    :cwe_id => line["CWE ID"],
    :cwe_text => line["CWE Text"],
    :date_public => line["Disclosure Date"] + "T00:00:00.000Z",
  }
  cve_data << new_cve
end

def convert_to_vulnogram(cve={})
  vendor = cve[:vendor_name]
  product = cve[:product_name]
  version = cve[:version_value]
  cwe = cve[:cwe_id]
  bug = cve[:cwe_text]

  auto_title = "#{vendor} #{product} #{cve[:cwe_text]}"
  auto_desc = "#{vendor} #{product} version #{version} suffers from an instance of #{cwe}: #{bug}."

  %Q{ {
  "data_type": "CVE",
  "data_format": "MITRE",
  "data_version": "4.0",
  "generator": {
    "engine": "Tod's Junk Converter #{VERSION}"
  },
  "CVE_data_meta": {
    "ID": "#{cve[:cve_id]}",
    "ASSIGNER": "cve@rapid7.com",
    "DATE_PUBLIC": "#{cve[:date_public]}",
    "TITLE": "#{auto_title}",
    "AKA": "",
    "STATE": "PUBLIC"
  },
  "affects": {
    "vendor": {
      "vendor_data": [
        {
          "vendor_name": "#{vendor}",
          "product": {
            "product_data": [
              {
                "product_name": "#{product}",
                "version": {
                  "version_data": [
                    {
                      "version_name": "",
                      "version_affected": "=",
                      "version_value": "#{version}",
                      "platform": ""
                    }
                  ]
                }
              }
            ]
          }
        }
      ]
    }
  },
  "problemtype": {
    "problemtype_data": [
      {
        "description": [
          {
            "lang": "eng",
            "value": "#{cwe}"
          },
          {
            "lang": "eng",
            "value": "#{bug}"
          }
        ]
      }
    ]
  },
  "description": {
    "description_data": [
      {
        "lang": "eng",
        "value": "#{auto_desc}"
      }
    ]
  },
  "references": {
    "reference_data": [
      {
        "refsource": "MISC",
        "url": "#{cve[:misc_ref]}",
        "name": "#{cve[:misc_ref]}"
      }
    ]
  },
  "exploit": [
    {
      "lang": "eng",
      "value": "#{cve[:misc_ref]}"
    }
  ]
}}
end

cve_data.each do |cve|
  id = cve[:cve_id]
  puts "Processing #{id}"
  fname = "#{id}.json"
  cve_formatted = convert_to_vulnogram(cve)
  File.open(fname, 'w') { |file| file.write cve_formatted}
end
