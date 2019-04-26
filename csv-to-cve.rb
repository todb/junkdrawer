#!/usr/bin/ruby

# This takes a CSV-formatted list of Metasploit modules
# that lack a CVE, and starts the assigning process. If the
# product is or was maintained by a CNA, that starts with
# an email. If it's not, Rapid7 can assign one as a researcher
# CNA.

require 'csv'
# require 'json' # Turns out, no JSON objects are here, just strings.

# NOTE: This assumes one single affected version, which is
# usually the case. If there is a known range of versions,
# then you'll need to monkey with that in the output manually.

VERSION = "0.0.3"

infile_name = ARGV[0]
begin
  csv = CSV.read(infile_name, :headers => true)
rescue
  puts "Can't read #{infile_name}."
  exit 1
end

cve_data = []

csv.each do |line|
  next if line["PR of JSON"] || line["Contact CNA?"] # Already submitted
  next unless line["Reserve CVE"]
  new_cve = {
    :cve_id => line["Reserve CVE"],
    :product_name => line["Product Name"],
    :version_value => line["Product Version"],
    :misc_ref => line["MISC Link"],
    :vendor_name => line["Vendor Name"],
    :cna_contact => line["CNA Contact"],
    :cwe_id => line["CWE ID"],
    :cwe_text => line["CWE Text"],
    :date_public => line["Disclosure Date"] + "T00:00:00.000Z",
  }
  cve_data << new_cve
end

def generate_cna_email(cve={})
  vendor = cve[:vendor_name]
  product = cve[:product_name]
  version = cve[:version_value]
  cwe = cve[:cwe_id]
  bug = cve[:cwe_text]
  ref = cve[:misc_ref]
  to = cve[:cna_contact]

  %Q{
To: #{to}
Subject: CVE request for #{product} #{version}

Hello! I'm writing to report a vulnerability that doesn't appear to have a CVE identifier assigned to it, and I'd like to rectify this. This came up during a review of Metasploit modules that appear to be exploiting a vulnerability that, for whatever reason, never got a CVE ID assigned. It's almost certainly an old issue in old software, but for completeness, I'd love to get this categorized correctly.

The Metasploit module can be found at: #{ref}

It appears that this is an instance of #{cwe}: #{bug}, affecting #{vendor} #{product} #{version}.

I'd really appreciate it if you can confirm that this is module, in fact, does exercise a vulnerability in a product you do or did maintain, and if you'd care to assign a CVE.

In the case that you decide against a CVE assignment, I'm happy to assign one as a researcher CNA for this vulnerability, presuming we have the vendor, product, version, and CWE correctly identified.

Thanks for your time!

-- 
"Tod Beardsley"
Director of Research
+1-512-438-9165 | https://keybase.io/todb
}

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
  if cve[:cna_contact]
    vendor = cve[:vendor_name].downcase.gsub(' ','_')
    fname = "notify_#{vendor}_#{cve[:cve_id]}.txt"
    puts "Processing #{fname}"
    cna_email = generate_cna_email(cve)
    File.open(fname, 'w') { |file| file.write cna_email}
  else
    id = cve[:cve_id]
    next unless id =~ /^CVE-/
    fname = "#{id}.json"
    puts "Processing #{fname}"
    cve_formatted = convert_to_vulnogram(cve)
    File.open(fname, 'w') { |file| file.write cve_formatted}
  end
end
