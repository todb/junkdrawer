#!/bin/bash

# Thanks ChatGPT!

# Default input file
default_input_file="epss-timeseries-v2023.03.01.csv"

# Output file for CVEs with significant changes
output_file="cves_with_significant_changes.csv"

# Default values for magnitude and days
magnitude=0.05
days=1
input_file="$default_input_file"  # Set default input file

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --magnitude) magnitude="$2"; shift ;;
        --days) days="$2"; shift ;;
        --file) input_file="$2"; shift ;;  # Set input file if provided
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

echo "Checking $input_file for changes of at least $magnitude over $days days..."
# Initialize the output file
echo "CVE,Change" > "$output_file"

# Read the first line to grab the dates (skip the CVE column)
IFS=',' read -r header_line < "$input_file"
# The first element is 'CVE', so we need to ignore that and grab the rest
dates=($(echo "$header_line" | cut -d, -f2-))

# Process the CSV file, starting from the second line (NR > 1)
awk -F, -v dates="${dates[*]}" -v magnitude="$magnitude" -v days="$days" -v input_file="$input_file" '
BEGIN {
    split(dates, date_arr, " ");  # Split dates into array
}
NR > 1 {
    cve = $1;
    for (i = NF - 1; i - days >= 2; i--) {  # Start from the last value and move backward
        sum_diff = 0;
        # Calculate the total difference over the defined window of days
        for (j = 0; j < days; j++) {
            value1 = $(i-j);
            value2 = $(i-j-1);
            if (value1 != "" && value2 != "") {
                diff = value1 - value2;  # Subtract the older value from the newer one to go backwards
                sum_diff += diff;
            }
        }

        # Ensure that we only record the change once for each window
        abs_sum_diff = (sum_diff < 0 ? -sum_diff : sum_diff);  # Absolute total difference
        if (abs_sum_diff >= magnitude) {
            # If the absolute total difference over the window is greater than or equal to magnitude
            printf "%s,%.5f\n", cve, sum_diff;
            break;  # Exit the loop after recording the change once for this window
        }
    }
}
' "$input_file" >> "$output_file"

echo "Results saved to $output_file"
echo "----"
cat $output_file
echo "----"
