# 🎥 macOS Video Rotator and Replacer Setup

This guide provides the Bash script and detailed instructions for setting up an hourly rotation task on macOS. The script cycles through a small pool of source video files (`.mov`) and uses their content to overwrite a larger set of target video files, preserving the original target filenames.

***

## 1. The Rotation Script: `hourly_rotator.sh`

This script handles gathering the files, reading the rotation index, performing the content replacement, and updating the index for the next hour.


#!/bin/bash

# --- Configuration ---
# Folder containing the files whose content will be overwritten (Target Files)
# NOTE: This is a system path and requires sudo/root access to write.
TARGET_DIR="/path/to/files" 
# Folder containing the 3 new files used for replacement (Source Files)
SOURCE_DIR="/path/to/files" 

# File to store the index of the last used source file (for rotation tracking)
INDEX_FILE="/tmp/rotator_index.txt"

## 2. For Scheduling on hourly basis (My preference) use Cron:

sudo crontab -e



# Run the video rotation script at the start of every hour (0th minute)
0 * * * * /path/to/hourly_rotator.sh




