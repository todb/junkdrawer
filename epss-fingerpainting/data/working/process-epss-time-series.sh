#!/bin/bash

# Thanks ChatGPT!

MODEL_VERSION="${1:-v2023.03.01}"
echo "Using model ${MODEL_VERSION} (specify a different one if you like, current is v2025.03.14)"

# Create a unique temp directory based on the process ID
temp_dir="temp_epss_merge_$$"
mkdir -p "$temp_dir"
echo "Temp dir is ${temp_dir}..."
# Ensure cleanup on exit (even on errors)
trap "rm -rf $temp_dir" EXIT

# Process files matching the model version
for file in cve-epss-percentile-*-"${MODEL_VERSION}".csv; do
    [[ -f "$file" ]] || continue  # Skip if no matching files
    echo "Extracting from $file..."

    # Extract date from filename
    date=$(echo "$file" | sed -n 's/cve-epss-percentile-\([0-9\-]*\)-.*/\1/p')

    # Extract only the CVE and EPSS columns (1st and 2nd)
    awk -F, '{print $1 "," $2}' "$file" > "${temp_dir}/${date}.csv"
done

# Merge all temp CSVs into a single time series CSV
output_file="epss-timeseries-${MODEL_VERSION}.csv"

# Get sorted list of all unique CVEs
awk -F, 'NR > 1 {print $1}' ${temp_dir}/*.csv | sort -u > "${temp_dir}/all_cves.txt"

# Prepare header row
echo -n "CVE" > "$output_file"
for f in ${temp_dir}/*.csv; do
    date=$(basename "$f" .csv)
    echo -n ",$date" >> "$output_file"
done
echo >> "$output_file"

# Merge data with full CVE progress output
while read -r cve; do
    echo "Processing CVE: $cve"
    echo -n "$cve" >> "$output_file"

    for f in ${temp_dir}/*.csv; do
        value=$(grep "^${cve}," "$f" | cut -d, -f2)
        echo -n ",$value" >> "$output_file"
    done
    echo >> "$output_file"
done < "${temp_dir}/all_cves.txt"

echo "Generated: $output_file"
