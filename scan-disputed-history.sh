#!/bin/zsh

set -euo pipefail
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auditing disputed CVEs..."

# Root of the cvelist git repo
REPO="../cvelistV5/"

cd "$REPO"

# Output files

echo -n > disputed-rejected.txt
echo -n > rejected-without-dispute.txt
echo -n > disputed-published.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')]" Gathering currently disputed CVEs

disputed_files=($(find cves/2025 -name '*.json' \
    -exec jq -r 'select(.containers.cna.tags and (.containers.cna.tags[] == "disputed")) | input_filename' {} +i))

disputed_total=${#disputed_files}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] There are $disputed_total disputed published CVEs "

printf "%s\n" "${disputed_files[@]}" > disputed-published.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gathering list of rejected CVE files..."

# Get all rejected CVE record filenames
rejected_files=($(find cves/2025 -name '*.json' \
    -exec jq -r 'select(.cveMetadata.state == "REJECTED") | input_filename' {} +))

total=${#rejected_files}
count=0

echo "Found $total rejected CVE records."
echo "Beginning history scan..."

for file in "${rejected_files[@]}"; do
    count=$((count+1))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$count/$total] scanning $file"

    # Flag for whether a disputed tag ever appeared
    had_disputed=0

    # Iterate through all revisions for this path
    # git rev-list lists all commits touching this path from latest backward
    for commit in $(git rev-list HEAD -- "$file"); do
        # Extract the file content at that commit
        content=$(git show "${commit}:${file}" 2>/dev/null || echo "")

        # Skip if empty or unreadable
        if [[ -z "$content" ]]; then
            continue
        fi

        # Check whether this revision had a disputed tag
        if echo "$content" | jq -e '.containers.cna.tags? | index("disputed")' >/dev/null 2>&1; then
            had_disputed=1
            break
        fi
    done

    if [[ $had_disputed -eq 1 ]]; then
        echo "$file" >> disputed-rejected.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $file was disputed!"
    else
        echo "$file" >> rejected-without-dispute.txt
    fi
done

wc -l disputed-published.txt disputed-rejected.txt rejected-without-dispute.txt
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done!"
