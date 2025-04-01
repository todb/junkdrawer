#!/bin/bash

# Thanks ChatGPT!

# Input CSV file (replace with your file)
input_file="test.csv"

# Output file for CVEs with significant changes
output_file="cves_with_significant_changes.csv"

# Configurable threshold for "a lot" change (default 0.05)
threshold=0.05

# Initialize the output file
echo "CVE,Change" > "$output_file"

# Read the first line to grab the dates (skip the CVE column)
IFS=',' read -r header_line < "$input_file"
# The first element is 'CVE', so we need to ignore that and grab the rest
dates=($(echo "$header_line" | cut -d, -f2-))

# Process the CSV file, starting from the second line (NR > 1)
awk -F, -v dates="${dates[*]}" -v threshold="$threshold" '
BEGIN {
    split(dates, date_arr, " ");  # Split dates into array
}
NR > 1 {
    cve = $1;
    for (i = 2; i < NF; i++) {
        value1 = $i;
        value2 = $(i+1);
        if (value1 != "" && value2 != "") {
            # Calculate the absolute difference between consecutive values
            diff = value2 - value1;
            abs_diff = (diff < 0 ? -diff : diff);  # Absolute difference
            if (abs_diff >= threshold) {
                # If the absolute difference is greater than or equal to threshold
                printf "%s,%.5f\n", cve, diff;
            }
        }
    }
}
' "$input_file" >> "$output_file"

echo "Results saved to $output_file"
