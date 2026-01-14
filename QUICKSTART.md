# 🚀 QUICKSTART - root-doha-apatch

**Estimated time:** 15-20 minutes

## TL;DR

```bash
# 1. Prepare the device
# - Install LineageOS 22.1
# - Enable USB Debugging
# - Connect to PC

# 2. Place APatch.apk in this folder
cp ~/Downloads/APatch.apk .

# 3. Run the script
bash scripts/setup_apatch.sh

# 4. Follow the interactive steps
# (The script will guide you at each step)

# 5. DONE! Persistent root
adb shell "su -c 'id'"
# uid=0(root) gid=0(root) ...
```

## Prerequisites

- ✅ **Device:** Moto G8 Plus (doha)
- ✅ **ROM:** LineageOS 22.1
- ✅ **Bootloader:** Unlocked
- ✅ **PC:** adb + fastboot configured
- ✅ **USB Debugging:** Enabled on device

## Detailed Steps

### 1️⃣ Prepare the Device

```bash
# On the device:
# Settings > About phone > tap "Build number" 7 times
# Settings > Developer options > USB Debugging ✓
# Connect USB cable
```

### 2️⃣ Download APatch.apk

```bash
# Download from: https://github.com/bmax121/APatch/releases
# Or copy if you already have it
cp /path/to/APatch.apk .
```

### 3️⃣ Run the Script

```bash
bash scripts/setup_apatch.sh
```

The script will:
- ✓ Extract boot.img
- ✓ Install APatch.apk
- ✓ Guide you through manual patching
- ✓ Flash patched boot
- ✓ Verify root
- ✓ Confirm persistence

### 4️⃣ During Execution

When the script prompts:

**Step A - Patch in app:**
1. Open APatch on device
2. "Select boot image" → choose extracted boot
3. "Patch" → wait for completion
4. "OK"
5. Come back and press ENTER in script

**Step B - Install persistent:**
1. Open APatch again
2. "Install" → wait for completion
3. "OK"

### 5️⃣ Verify

```bash
# Script automatically verifies, but you can check manually:
adb shell "su -c 'id'"
# Should show: uid=0(root)

# Additional reboot to confirm persistence:
adb reboot
sleep 60
adb shell "su -c 'id'"
# Should STILL show: uid=0(root)
```

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| `adb: device not found` | Enable USB Debugging + Authorize device |
| `permission denied` in dd | Run `adb root` first |
| APatch "Install" every reboot | Press "Install" a 2nd time |
| Device doesn't boot | Go back to fastboot + flash ROM again |
| Root disappears | APatch requires persistent install (Step B) |

## Important Files

```
.
├── README.md           ← Complete documentation
├── NOTES.md            ← Technical details
├── LICENSE             ← MIT License
└── scripts/
    └── setup_apatch.sh ← Main script (RUN THIS)
```

## Compatibility

- ✅ Motorola G8 Plus (doha, XT2019-2)
- ✅ LineageOS 22.1 (Android 15)
- ✅ APatch v0.12.2+
- ❌ Other devices (adaptable but not tested)

## After Root

Now you can:
- 📱 Install apps requiring root
- 🔐 Use Magisk modules (if you install Magisk later)
- 🛡️ Modify system with root access
- 🔌 Use ADB as superuser

## Need Help?

1. Read `README.md` for complete documentation
2. Read `NOTES.md` for technical details
3. Check logs: `adb logcat -d | grep -i apatch`
4. Report at [APatch Issues](https://github.com/bmax121/APatch/issues)

---

**Version:** 1.0 | **Last updated:** 2026-01-14 | **Status:** ✅ Tested

**Get started now: `bash scripts/setup_apatch.sh`**
