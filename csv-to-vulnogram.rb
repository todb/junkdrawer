#!/usr/bin/ruby

require 'csv'
require 'json'

infile_name = ARGV[0]
begin
  csv = CSV.read(infile_name, :headers => true)
rescue
  puts "Can't read #{infile_name}."
  exit 1
end

cve_data = []

csv.each do |line|
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
  auto_title = "#{cve[:vendor_name]} #{cve[:product_name]} #{cve[:cwe_text]}"
  %Q{ {
  "data_type": "CVE",
  "data_format": "MITRE",
  "data_version": "4.0",
  "generator": {
    "engine": "Tod's Junk Converter 0.0.1"
  },
  "CVE_data_meta": {
    "ID": "#{cve[:cve_id]}",
    "ASSIGNER": "cve@rapid7.com",
    "DATE_PUBLIC": "#{cve[:date_public]}",
    "TITLE": "#{auto_title}",
    "AKA": "",
    "STATE": "PUBLIC"
  },
  "source": {
    "defect": [],
    "advisory": "",
    "discovery": "UNKNOWN"
  },
  "affects": {
    "vendor": {
      "vendor_data": [
        {
          "vendor_name": "#{cve[:vendor_name]}",
          "product": {
            "product_data": [
              {
                "product_name": "#{cve[:product_name]}",
                "version": {
                  "version_data": [
                    {
                      "version_name": "",
                      "version_affected": "=",
                      "version_value": "#{cve[:version_value]}",
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
            "value": "#{cve[:cwe_id]}"
          },
          {
            "lang": "eng",
            "value": "#{cve[:cwe_text]}"
          }
        ]
      }
    ]
  },
  "description": {
    "description_data": [
      {
        "lang": "eng",
        "value": ""
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
  "configuration": [],
  "exploit": [
    {
      "lang": "eng",
      "value": "#{cve[:misc_ref]}"
    }
  ],
  "work_around": [],
  "solution": [],
  "credit": []
}}
end

cve_data.each do |cve|
  id = cve[:cve_id]
  puts "Processing #{id}"
  fname = "#{id}.json"
  cve_formatted = convert_to_vulnogram(cve)
  File.open(fname, 'w') { |file| file.write cve_formatted}
end