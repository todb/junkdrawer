#!/bin/zsh

extensions="gif|jpg|jpeg|png|bmp|webp|heic|tiff|raw|heif|svg|ico|apng|avif|jp2|indd|pdf|eps|mov|mp4|avi|mkv|flv|wmv|webm"

start_dir="${1:-.}"

# Build a find cmd based on extensions
find_cmd="find \"$start_dir\" -type f \( "
for ext in ${(s:|:)extensions}; do
  find_cmd+="-iname \"*.$ext\" -o "
done

# Remove the last " -o "
find_cmd=${find_cmd% -o }
find_cmd+=" \)"

# Get the unique file extensions and create directories for them
rm -rf /tmp/fb-images/
echo "Creating directories for found extensions..."
eval "$find_cmd" | \
  sed -E "s/.*\.($extensions)$/\1/" | \
  sort | uniq | while read -r ext; do
    mkdir -p "/tmp/fb-images/$ext"
  done

# Count all the target files we're copying
echo "File counts:"
eval "$find_cmd" | \
  sed -E "s/.*\.($extensions)$/\1/" | \
  sort | uniq -c | tee /tmp/file_counts.txt

echo "Copying files..."

# Loop over each file extension and copy the files to the appropriate directory
eval "$find_cmd" | \
  sed -E "s/.*\.($extensions)$/\1/" | \
  sort | uniq -c | while read -r count ext; do
    echo "Copying $count $ext files..."
    find "$start_dir" -type f -iname "*.$ext" | while read -r file; do
      dest_dir="/tmp/fb-images/$ext"
      cp "$file" "$dest_dir/"
    done
  done

echo "File sorting complete."
