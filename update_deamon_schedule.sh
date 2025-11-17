#!/bin/bash

# --- CONFIGURATION (MUST BE ABSOLUTE PATHS) ---
PLIST_FILE_SOURCE="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
PLIST_DAEMON="/Library/LaunchDaemons/com.yourname.rotator.plist" # Target Daemon path
DAEMON_LABEL="com.yourname.rotator"                              # Target Daemon Label

PLISTBUDDY="/usr/libexec/PlistBuddy"

# --- 1. READ THE USER'S CURRENT SCREEN SAVER SHUFFLE SETTING ---

# Read the custom integer code (e.g., 4683 for Every Day)
SHUFFLE_CODE=$("$PLISTBUDDY" -c 'Print :SystemDefault:Idle:Content:Shuffle:Duration:0' "$PLIST_FILE_SOURCE" 2>/dev/null)
SHUFFLE_TYPE=$("$PLISTBUDDY" -c 'Print :SystemDefault:Idle:Content:Shuffle:Type' "$PLIST_FILE_SOURCE" 2>/dev/null)

# 2. DETERMINE THE TARGET INTERVAL IN SECONDS
TARGET_INTERVAL=0

if [[ "$SHUFFLE_TYPE" == "continous" ]]; then
    # Continuously: Set to a minimum rotation time (e.g., 600 seconds / 10 minutes)
    # Note: Use a reasonable interval to avoid excessive CPU usage.
    TARGET_INTERVAL=600 
    STATUS_TEXT="Continuously (set to 600s interval)"

elif [[ "$SHUFFLE_TYPE" == "afterDuration" ]]; then
    # Timed Durations (Every Day / 12 Hours)
    
    if [[ "$SHUFFLE_CODE" == "4683" ]]; then
        TARGET_INTERVAL=86400  # Every Day
        STATUS_TEXT="Every Day"
        
    elif [[ "$SHUFFLE_CODE" == "2341" ]]; then
        TARGET_INTERVAL=43200  # Every 12 Hours
        STATUS_TEXT="Every 12 Hours"
    
    else
        echo "WARNING: Unknown Shuffle Code ($SHUFFLE_CODE). Keeping previous interval."
        exit 1
    fi
else
    # Default state (Static/Ventura/Not Shuffling) - Set to a long default time
    TARGET_INTERVAL=36000 # 10 hours for static images
    STATUS_TEXT="Static/Off"
fi

echo "Setting Daemon schedule to: $STATUS_TEXT ($TARGET_INTERVAL seconds)"

# --- 3. WRITE THE NEW INTERVAL TO THE LAUNCHDAEMON PLIST ---

# Write the new integer value to the StartInterval key in the LaunchDaemon plist.
# Ensure the key is of type <integer> and not <string>
$PLISTBUDDY -c "Set :StartInterval $TARGET_INTERVAL" "$PLIST_DAEMON"

# --- 4. RELOAD THE DAEMON TO APPLY CHANGES ---

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Updated $PLIST_DAEMON. Forcing service reload..."
    
    # Reload the service using its label (MUST be run as root)
    launchctl unload "$PLIST_DAEMON"
    launchctl load "$PLIST_DAEMON"
    
    echo "Daemon schedule updated successfully."
else
    echo "ERROR: PlistBuddy failed to write the new interval."
fi
