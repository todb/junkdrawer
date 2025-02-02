#!/bin/zsh

# Note, this writes and reads from tmp in nonsecure ways. Don't use this to
# parse untrusted inputs. It also creates dynamic cmd line arguments. Also
# a bad idea.

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

echo "Copying unique files. This hashing will take a minute."

temp_file=$(mktemp)

# Loop over each file and generate hashes
eval "$find_cmd" | while read -r file; do
    # Generate the file's hash
    hash=$(shasum "$file" | awk '{print $1}')
    
    # Check if the hash is already in the temp file (i.e., duplicate)
    if ! grep -q "$hash" "$temp_file"; then
        ext=$(echo "$file" | sed -E "s/.*\.($extensions)$/\1/")
        dest_dir="/tmp/fb-images/$ext"
        
        # Copy the unique file to its destination
        cp "$file" "$dest_dir/"
        
        # Add the hash to the temp file to track it
        echo "$hash" >> "$temp_file"
    fi
done

# Clean up the temporary file
rm -f "$temp_file"

echo "File sorting complete."
