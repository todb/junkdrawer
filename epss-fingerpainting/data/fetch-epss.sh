#!/bin/bash

# Thanks ChatGPT!

START_DATE=""
END_DATE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --start)
      START_DATE="$2"
      shift 2
      ;;
    --end)
      END_DATE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate input dates
if [[ -z "$START_DATE" || -z "$END_DATE" ]]; then
  echo "Usage: $0 --start YYYY-MM-DD --end YYYY-MM-DD"
  exit 1
fi

# Determine OS and use appropriate date commands
if date -d "2025-01-01" >/dev/null 2>&1; then
  # Linux date command
  START_EPOCH=$(date -d "$START_DATE" +%s)
  END_EPOCH=$(date -d "$END_DATE" +%s)
  CURRENT_EPOCH=$(date +%s)
elif date -j -f "%Y-%m-%d" "2025-01-01" "+%s" >/dev/null 2>&1; then
  # MacOS date command
  START_EPOCH=$(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")
  END_EPOCH=$(date -j -f "%Y-%m-%d" "$END_DATE" "+%s")
  CURRENT_EPOCH=$(date +%s)
else
  echo "Unsupported OS: Unable to determine date format."
  exit 1
fi

if [[ $START_EPOCH -gt $END_EPOCH ]]; then
  echo "Error: Start date must be before or equal to end date."
  exit 1
fi

if [[ $END_EPOCH -gt $CURRENT_EPOCH ]]; then
  echo "Error: End date cannot be in the future."
  exit 1
fi

# Do the thing
CURRENT_EPOCH=$START_EPOCH
while [[ $CURRENT_EPOCH -le $END_EPOCH ]]; do
  if date -d @0 >/dev/null 2>&1; then
    CURRENT_DATE=$(date -d @$CURRENT_EPOCH +%Y-%m-%d)  # Linux
  else
    CURRENT_DATE=$(date -j -f "%s" "$CURRENT_EPOCH" +%Y-%m-%d)  # MacOS
  fi

  FILE_URL="https://epss.cyentia.com/epss_scores-$CURRENT_DATE.csv.gz"
  echo "Fetching: $FILE_URL"

  curl -LO -f --retry 3 --retry-delay 3 "$FILE_URL"

  if [[ $? -ne 0 ]]; then
    echo "Failed to download $FILE_URL"
  fi

  sleep 3

  # Increment by one day (86400 seconds)
  CURRENT_EPOCH=$((CURRENT_EPOCH + 86400))
done

echo "Done!"
