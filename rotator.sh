# 🎥 macOS Video Rotator and Replacer Setup

This guide provides the Bash script and detailed instructions for setting up an hourly rotation task on macOS. The script cycles through a small pool of source video files (`.mov`) and uses their content to overwrite a larger set of target video files, preserving the original target filenames.

***

## 1. The Rotation Script: `hourly_rotator.sh`

This script handles gathering the files, reading the rotation index, performing the content replacement, and updating the index for the next hour.

```bash
#!/bin/bash

# --- Configuration ---
# Folder containing the 20 files whose content will be overwritten (Target Files)
# NOTE: This is a system path and requires sudo/root access to write.
TARGET_DIR="/path/to/20_mov_files" 
# Folder containing the 3 new files used for replacement (Source Files)
SOURCE_DIR="/path/to/3_new_mov_files" 

# File to store the index of the last used source file (for rotation tracking)
INDEX_FILE="/tmp/rotator_index.txt"

# --- Main Logic ---

# 1. Gather all target files (the 20 files to be overwritten)
TARGET_FILES=()
while IFS= read -r -d $'\0' file; do
    TARGET_FILES+=("$file")
done < <(find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.mov" -print0)

# 2. Gather all source files (the 3 new files)
SOURCE_FILES=()
while IFS= read -r -d $'\0' file; do
    SOURCE_FILES+=("$file")
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -iname "*.mov" -print0)

SOURCE_COUNT=${#SOURCE_FILES[@]}

if [[ $SOURCE_COUNT -eq 0 ]]; then
    echo "Error: No source files found in $SOURCE_DIR. Exiting."
    # Exit code 1 indicates failure
    exit 1
fi

# 3. Determine the current rotation index
# Read index from file or start at 0 if file doesn't exist
if [[ -f "$INDEX_FILE" ]]; then
    CURRENT_INDEX=$(cat "$INDEX_FILE")
else
    CURRENT_INDEX=0
fi

# Calculate the index of the file to use for this run (using modulo arithmetic)
FILE_INDEX=$((CURRENT_INDEX % SOURCE_COUNT))
FILE_TO_USE="${SOURCE_FILES[$FILE_INDEX]}"

echo "--- $(date) ---"
echo "Rotation Index: $CURRENT_INDEX. Using source file: $(basename "$FILE_TO_USE")"

# 4. Loop through all 20 target files and replace content
for target_file in "${TARGET_FILES[@]}"; do
    # cp -f: Copy (overwrite) the content of the source file to the target file
    # This is the command that generated the "Permission denied" error if run without sudo.
    cp -f "$FILE_TO_USE" "$target_file"
    echo "  Replaced content of: $(basename "$target_file")"
done

# 5. Save the next rotation index
NEXT_INDEX=$((CURRENT_INDEX + 1))
echo "$NEXT_INDEX" > "$INDEX_FILE"
echo "Next rotation index set to: $NEXT_INDEX"
