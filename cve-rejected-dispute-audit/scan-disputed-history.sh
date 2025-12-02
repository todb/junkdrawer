#!/bin/zsh

set -euo pipefail
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting CVE audit..."

# Root of the cvelist git repo
REPO="../cvelistV5/"
cd "$REPO"

# Output files
echo -n > rejected.txt
echo -n > disputed-today.txt
echo -n > rejected-after-published.txt
echo -n > rejected-after-disputed.txt
echo -n > rejected-unpublished.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gathering currently disputed CVEs (latest commit)"

disputed_files=($(find cves/2025 -name '*.json' \
    -exec jq -r 'select(.containers.cna.tags and (.containers.cna.tags[] == "disputed")) | input_filename' {} +i))

disputed_total=${#disputed_files}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $disputed_total currently disputed CVEs"
printf "%s\n" "${disputed_files[@]}" > disputed-today.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gathering rejected CVE files..."

rejected_files=($(find cves/2025 -name '*.json' \
    -exec jq -r 'select(.cveMetadata.state == "REJECTED") | input_filename' {} +))

total=${#rejected_files}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $total rejected CVE records"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Beginning history scan of rejected CVEs..."

count=0
for file in "${rejected_files[@]}"; do
    count=$((count+1))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$count/$total] scanning $file"

    had_disputed=0
    had_published=0

    # Scan git history
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

        # Stop early if both flags found
        [[ $had_disputed -eq 1 && $had_published -eq 1 ]] && break
    done

    # Write to rejected.txt (all rejected)
    echo "$file" >> rejected.txt

    # Categorize
    if [[ $had_disputed -eq 1 ]]; then
        echo "$file" >> rejected-after-disputed.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $file: rejected after disputed"
    elif [[ $had_published -eq 1 ]]; then
        echo "$file" >> rejected-after-published.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $file: rejected after published"
    else
        echo "$file" >> rejected-unpublished.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $file: rejected without ever being published"
    fi
done

wc -l rejected.txt disputed-today.txt rejected-after-published.txt rejected-after-disputed.txt rejected-unpublished.txt
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done!"
