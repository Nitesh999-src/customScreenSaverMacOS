# 🚀 macOS Video Rotator: System Setup Guide

This guide details the system-level steps required to configure and deploy the video rotator script on a macOS machine.

This setup assumes you have the following files from the repository:
* `rotator.sh` (The main script, which performs the rotation)
* `update_daemon_schedule.sh` (The optional script, which reads the settings and updates the schedule)
* `com.yourname.rotator.plist` (The `launchd` scheduler file)

---

## ⚠️ 1. Critical Prerequisites: Security & Permissions

Before you begin, understand these two core macOS concepts:

* **TCC (Privacy):** macOS blocks automated processes (like this script) from accessing user folders like `Desktop`, `Documents`, or `Downloads`.
    * **Solution:** Your **Source Files** and **Script** must be placed in a non-protected location (e.g., `/Users/YOUR_USER/Scripts/` or `/usr/local/bin/`).

* **Root Access:** To write to system folders (like `/Library/Application Support/...`), the script must run as the **root user**.
    * **Solution:** We will use a **LaunchDaemon**, which runs as root, instead of a user-level `cron` job or LaunchAgent.

---

## 2. ⚙️ Step 1: Configure Files

First, you must edit the script and `.plist` files to match your system's paths.

### A. Configure the Rotation Script (`rotator.sh`)

1.  Open `rotator.sh` in a text editor.
2.  Update the **absolute paths** for the two directory variables at the top of the file:

    ```bash
    # (Inside rotator.sh)
    
    # 1. Set this to your TARGET folder (the one files are copied TO)
    TARGET_DIR="/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS" 
    
    # 2. Set this to your SOURCE folder (the one files are copied FROM)
    SOURCE_DIR="/Users/YOUR_USER/Scripts/Source_Media" 
    ```

### B. Configure the Scheduler (`.plist`)

1.  Open `com.yourname.rotator.plist` in a text editor.
2.  Verify the path in `ProgramArguments` matches where you will place the rotation script (we recommend `/usr/local/bin/rotator.sh`). **Note:** This will be changed in the optional step below.
3.  Change the `StartInterval` integer to your desired frequency (in seconds).
    * **120** = Every 2 minutes
    * **3600** = Every 1 hour

    ```xml
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/rotator.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer> 
    ```

---

## 3. 📂 Step 2: Place Files in System Locations

Now, move the configured files to their final destinations using the `Terminal`.

1.  **Create a safe "Source" directory** (if it doesn't exist) and move your source media files into it.
    ```bash
    mkdir -p /Users/YOUR_USER/Scripts/Source_Media
    mv /path/to/your/source-files/* /Users/YOUR_USER/Scripts/Source_Media/
    ```

2.  **Move the `rotator.sh` script** (and `update_daemon_schedule.sh` if using the optional feature) to a system binary folder and make them executable.
    ```bash
    sudo mv /path/to/rotator.sh /usr/local/bin/rotator.sh
    sudo chmod +x /usr/local/bin/rotator.sh
    
    # IF USING DYNAMIC SCHEDULING:
    sudo mv /path/to/update_daemon_schedule.sh /usr/local/bin/update_daemon_schedule.sh
    sudo chmod +x /usr/local/bin/update_daemon_schedule.sh
    ```

3.  **Move the `.plist` file** to the system's LaunchDaemons folder.
    ```bash
    sudo mv /path/to/com.yourname.rotator.plist /Library/LaunchDaemons/
    ```

---

## 4. 🚀 Optional: Automate Timing from Settings (Advanced)

If you want the rotation interval (e.g., "Every Day") to be controlled directly by the macOS Screen Saver setting, you must use the dynamic scheduler script.

### A. Rationale

The LaunchDaemon cannot read the user's settings itself. We run the `update_daemon_schedule.sh` script every 10 minutes (or another short interval) to check the user's setting and rewrite the `StartInterval` in the LaunchDaemon's XML file.

### B. Configuration

1.  **Change the `ProgramArguments` in your `.plist`** (`/Library/LaunchDaemons/com.yourname.rotator.plist`) to point to the update script instead of the rotation script:

    ```xml
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/update_daemon_schedule.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>600</integer> ```

2.  **Ensure your `update_daemon_schedule.sh` script is configured** to call the `rotator.sh` script inside its logic.

---

## 5. 🔑 Step 3: Set Permissions and Load the Daemon

This final step activates the scheduled task.

1.  **Set correct ownership on the `.plist` file.** This is **mandatory** for `launchd` to accept the file.
    ```bash
    sudo chown root:wheel /Library/LaunchDaemons/com.yourname.rotator.plist
    ```

2.  **Load the daemon.** This tells macOS to register and start your automated task.
    ```bash
    sudo launchctl load /Library/LaunchDaemons/com.yourname.rotator.plist
    ```

---

## 6. 🔎 Step 4: Monitor and Verify

Check the log files to ensure the script is running correctly without errors. The log paths are defined inside your `.plist` file.

```bash
# Check the main output log
tail -f /var/log/rotator.log

# Check the error log (if you defined a separate one)
tail -f /var/log/rotator.error.log
