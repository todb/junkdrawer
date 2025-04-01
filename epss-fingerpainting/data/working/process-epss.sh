#!/bin/bash

# Thanks ChatGPT!

# Process each CSV file in the cwd
for file in epss_scores-*.csv; do
    first_line=$(head -n 1 "$file")
    model_version=$(echo "$first_line" | sed -n 's/^#model_version:\([^,]*\).*/\1/p')
    score_date=$(echo "$first_line" | sed -n 's/.*score_date:\([0-9\-]*\)T.*/\1/p')
    # If extraction failed, alert and break
    if [[ -z "$model_version" || -z "$score_date" ]]; then
        echo "Halting on $file due to missing metadata"
        exit 2
    fi

    new_filename="cvs-epss-percentile-${score_date}-${model_version}.csv"
    # Remove the first two lines and save as the new file
    tail -n +3 "$file" > "$new_filename"
    echo "Processed $file -> $new_filename"
done
