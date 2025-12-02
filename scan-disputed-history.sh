#!/bin/zsh

set -euo pipefail
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auditing disputed CVEs..."

# Root of the cvelist git repo
REPO="/Users/todbeardsley/git/cvelistV5/"
cd "$REPO"

# Output files
echo -n > disputed-rejected.txt
echo -n > rejected-without-dispute.txt
echo -n > disputed-published.txt
echo -n > published-rejected.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gathering currently disputed CVEs"

disputed_files=($(find cves/2025 -name '*.json' \
    -exec jq -r 'select(.containers.cna.tags and (.containers.cna.tags[] == "disputed")) | input_filename' {} +i))

disputed_total=${#disputed_files}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] There are $disputed_total disputed published CVEs"

printf "%s\n" "${disputed_files[@]}" > disputed-published.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gathering list of rejected CVE files..."

rejected_files=($(find cves/2025 -name '*.json' \
    -exec jq -r 'select(.cveMetadata.state == "REJECTED") | input_filename' {} +))

total=${#rejected_files}
count=0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $total rejected CVE records."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Beginning history scan..."

for file in "${rejected_files[@]}"; do
    count=$((count+1))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$count/$total] scanning $file"

    had_disputed=0
    had_published=0

    for commit in $(git rev-list HEAD -- "$file"); do
        content=$(git show "${commit}:${file}" 2>/dev/null || echo "")
        [[ -z "$content" ]] && continue

        # Check for disputed tag
        if echo "$content" | jq -e '.containers.cna.tags? | index("disputed")' >/dev/null 2>&1; then
            had_disputed=1
        fi

        # Check for published state
        if echo "$content" | jq -e '.cveMetadata.state == "PUBLISHED"' >/dev/null 2>&1; then
            had_published=1
        fi

        # If both flags are found, no need to continue scanning commits
        [[ $had_disputed -eq 1 && $had_published -eq 1 ]] && break
    done

    if [[ $had_disputed -eq 1 ]]; then
        echo "$file" >> disputed-rejected.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $file was disputed!"
    else
        echo "$file" >> rejected-without-dispute.txt
    fi

    if [[ $had_published -eq 1 ]]; then
        echo "$file" >> published-rejected.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $file was previously published!"
    fi
done

wc -l disputed-published.txt disputed-rejected.txt rejected-without-dispute.txt published-rejected.txt
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done!"
