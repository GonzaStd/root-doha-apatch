# 🛠️ TROUBLESHOOTING - root-doha-apatch

## Common Problems

### ❌ `adb: device not found`

**Symptoms:**
```
$ adb devices
List of devices attached
$ ./setup_apatch.sh
adb: device not found
```

**Possible causes:**
1. USB Debugging not enabled
2. Computer not authorized on device
3. Defective USB cable
4. ADB drivers not installed

**Solutions:**

**Step 1: Enable USB Debugging**
```bash
# On the DEVICE (physically):
Settings
  > System
    > About phone
      > Tap "Build number" 7 times
        ← Device will say "You are now a developer"

Settings
  > System
    > Developer options
      > USB Debugging ✓ (enable)
```

**Step 2: Authorize this computer**
```bash
# Connect USB cable
# Pop-up should appear on device:
# "Allow USB debugging from this computer?"
# ✓ Press ALLOW
# ✓ Check "Always allow from this computer" (optional)
```

**Step 3: Reconnect ADB**
```bash
adb kill-server
adb start-server
adb devices
# Should show: ZY2276XGKK device
```

**If still not working:**
```bash
# Reinstall drivers
fastboot --version  # Verify installation

# On Windows (use zadig if needed)
# On Linux: already included in android-platform-tools
# On macOS: brew install android-platform-tools
```

---

### ❌ `APatch.apk not found`

**Symptoms:**
```
./setup_apatch.sh
[✗] APatch.apk not found in current folder
```

**Solution:**
```bash
# Download from:
# https://github.com/bmax121/APatch/releases

# Or copy if you already have it:
cp ~/Downloads/APatch.apk .

# Verify:
ls -lh APatch.apk
```

---

### ❌ `dd: permission denied`

**Symptoms:**
```
Extracting boot.img...
dd: open('/dev/block/bootdevice/by-name/boot_b'): Permission denied
```

**Cause:**
The `adb root` command didn't work correctly.

**Solution:**
```bash
# On PC:
adb kill-server
adb start-server
adb root
sleep 2

# Verify now returns uid=0:
adb shell "id"
# uid=0(root) gid=0(root) ...

# If still not working:
# 1. Reboot device
# 2. Enable "Developer options" again
# 3. Run script again
```

---

### ❌ `Boot image not found` (on device)

**Symptoms:**
During patching step, APatch can't see boot.img

**Cause:**
File not copied correctly to device, or APatch looking in different location.

**Solution:**
```bash
# Verify what files on device:
adb shell "ls -la /sdcard/"
adb shell "ls -la /sdcard/Downloads/"
adb shell "ls -la /data/local/tmp/"

# If not there, copy manually:
adb push boot_b.img /sdcard/
adb push boot_b.img /data/local/tmp/

# Then in APatch:
"Select boot image" → navigate to /sdcard/ or /data/local/tmp/
```

---

### ❌ `Patched boot not found` after patching

**Symptoms:**
```
[✗] No patched boot found on device
Expected locations:
  - /data/adb/ap/backup/boot.img
  - /data/adb/ap/backup/boot_patched.img
  - ...
```

**Causes:**
1. Patching failed in APatch app
2. APatch saves in different location
3. File permissions

**Solution:**

**Option A: Export manually from APatch**
```bash
# On device in APatch app:
# After clicking "Patch", look for "Export" or "Save" button
# Save file to /sdcard/

# Then on PC:
adb pull /sdcard/boot_patched.img ./
adb push boot_patched.img /data/local/tmp/boot_patched.img
```

**Option B: Search in alternative locations**
```bash
# On PC:
adb shell "find /data -name '*boot*' -o -name '*patch*' 2>/dev/null"
adb shell "find /sdcard -name '*boot*' -o -name '*patch*' 2>/dev/null"

# Once found:
adb pull /found/path/boot_patched.img ./
```

**Option C: Retry patching**
```bash
# On device:
# Open APatch again
# "Select boot image" → boot_b.img
# "Patch" → wait for completion
# Press "OK"
# Wait to see where file was saved
```

---

### ❌ `Device doesn't boot` after flashing

**Symptoms:**
- Device stuck in bootloader
- Or hangs on LineageOS splash screen
- Or infinite reboots

**Importance:** ⚠️ CRITICAL - Possible soft-brick

**Solution (Recovery):**

```bash
# 1. Reboot to recovery
fastboot reboot recovery

# 2. In recovery: "Wipe data/factory reset"
# 3. In recovery: Flash complete ROM again
adb reboot recovery
# Then in recovery: Apply update from ADB > sideload
adb sideload lineage-22.1-*.zip

# 4. Reboot
adb reboot

# 5. Device should boot normally (without root)
# 6. Start script again from beginning
```

**If recovery also doesn't boot:**
```bash
# Contact APatch support or restore to stock firmware
```

---

### ⚠️ `APatch shows "Install" after reboot`

**Symptoms:**
- After first reboot, open APatch
- Says "Running" but also shows "Install"
- This is NORMAL

**Explanation:**
APatch hadn't installed its persistent binaries in `/system/bin/su` yet.

**Solution (Normal):**
```bash
# This is EXPECTED after first reboot

# 1. Open APatch on device
# 2. Press "Install"
# 3. Wait 1-2 minutes
# 4. Press "OK"
# 5. Reboot again
adb reboot
sleep 60

# 6. Verify now persists:
adb shell "su -c 'id'"
# uid=0(root) ← IF PERSISTS, success!
```

---

### ❌ `Root disappears after reboot`

**Symptoms:**
```bash
adb shell "su -c 'id'"
# Works

adb reboot
sleep 60
adb shell "su -c 'id'"
# /system/bin/sh: su: inaccessible or not found
```

**Cause:**
APatch didn't complete persistent installation correctly.

**Solution:**

**Step 1: Reinstall from APatch**
```bash
# On device:
# 1. Open APatch
# 2. Press "Install" (Install)
# 3. Wait for completion
# 4. Press "OK"
```

**Step 2: Reboot confirmation**
```bash
# On PC:
adb reboot
sleep 60
adb shell "su -c 'id'"
# Should show uid=0(root)
```

**Step 3: If still not persistent**
```bash
# Possible /system corruption
# Reflash ROM completely:

adb reboot recovery
# In recovery: Wipe data/factory reset
# In recovery: Apply update from ADB
adb sideload lineage-22.1-*.zip

# Then try rooting from beginning
bash setup_apatch.sh
```

---

### ⚠️ `SELinux violations in logs`

**Symptoms:**
```bash
adb shell "logcat -d | grep -i 'avc.*denied'"
# Multiple "avc: denied" lines
```

**Explanation:**
It's normal for APatch to generate some SELinux denials. Doesn't affect functionality.

**Verification:**
```bash
# If root still works, ignore warnings:
adb shell "su -c 'id'"
# uid=0(root) ← If works, all good
```

---

### ❌ `Script fails to find patched boot`

**Symptoms:**
```
[✗] No patched boot found on device
Solution: try exporting manually from APatch
```

**Manual steps:**

```bash
# 1. On device in APatch:
# - Press "Select boot image" → boot_b.img
# - Press "Patch"
# - When done, look for "Export" or similar button
# - Save to /sdcard/boot_patched.img

# 2. On PC:
adb pull /sdcard/boot_patched.img ./

# 3. Flash manually:
adb push boot_patched.img /data/local/tmp/
adb root
sleep 2
adb shell "dd if=/data/local/tmp/boot_patched.img of=/dev/block/mmcblk0p54 bs=4M && sync"
adb reboot

# 4. Continue with manual verification
```

---

## System Health Verification

After completing installation, verify:

```bash
# 1. Root functional
adb shell "su -c 'id'"
# Should show: uid=0(root) gid=0(root)

# 2. Binaries in place
adb shell "ls -la /system/bin/su"
# -rwxr-xr-x (or similar)

# 3. Kernel patch active
adb shell "dmesg | grep -i 'kpatch\|apatch'" | head
# May not show anything (it's ok)

# 4. APatch app installed
adb shell "pm list packages | grep apatch"
# package:me.bmax.apatch

# 5. Reboot and persistence
adb reboot
sleep 60
adb shell "su -c 'id'"
# Should persist
```

---

## Contact/Support

If problem persists:

1. **Review detailed logs:**
   ```bash
   adb logcat -d > logcat.txt
   adb shell "cat /tmp/recovery.log" > recovery.txt
   adb shell "dmesg > dmesg.txt"
   ```

2. **Support repositories:**
   - APatch Issues: https://github.com/bmax121/APatch/issues
   - LineageOS doha: XDA-Developers forum

3. **Useful info for report:**
   - Output of `adb shell "getprop"`
   - Logs from `logcat`, `dmesg`, `recovery.log`
   - Exact APatch version
   - LineageOS version

---

**Last updated:** 2026-01-14 | **Version:** 1.0
