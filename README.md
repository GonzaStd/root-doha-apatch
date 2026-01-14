# Root Motorola G8 Plus with APatch

Complete and automated guide to root the **Motorola G8 Plus (doha)** with **LineageOS 22.1** using **APatch v0.12.2**.

## ⚠️ Prerequisites

- **Device:** Motorola G8 Plus (XT2019-2, codename: doha)
- **ROM:** LineageOS 22.1 (UNOFFICIAL build, or similar)
  - Download from: [XDA Thread](https://xda-developers.com)
- **Required State:**
  - Bootloader unlocked (`flashing_unlocked`)
  - Verity disabled (`vbmeta state: disabled`)
  - Device in clean firmware state (no previous root)
- **PC Tools:**
  - `adb` and `fastboot` configured
  - Python 3.x (optional, for enhanced script)
  - `git`

## 📋 Verified Compatibility

✅ Motorola G8 Plus (doha, XT2019-2)
✅ LineageOS 22.1 (build 2025-03-18, UNOFFICIAL-amogus_doha)
✅ APatch v0.12.2 (build 11142)
✅ Bootloader MBM-3.0 with Preflash validation enabled
✅ Kernel 4.14.190+ with SELinux

**Note:** This guide **WILL NOT** work with direct fastboot due to `Preflash validation` on Motorola bootloader. The solution is to use `dd` via ADB root.

---

## 🚀 Installation Process

### Step 0: Preparation

1. **Download required files:**
   ```bash
   # Download LineageOS 22.1 ROM
   # Download APatch.apk from: https://github.com/bmax121/APatch/releases
   ```

2. **Install clean ROM on device:**
   - Reboot to recovery
   - Wipe data/factory reset
   - Flash ROM via sideload: `adb sideload lineage-22.1-*.zip`
   - Reboot to system

3. **Enable USB Debugging:**
   - Settings > System > About phone
   - Tap "Build number" 7 times
   - Settings > System > Developer options
   - Enable "USB Debugging"
   - Authorize this computer in the pop-up

### Step 1: Run the Automated Script

```bash
# Place APatch.apk in the scripts/ folder
cd root-doha-apatch
bash scripts/setup_apatch.sh
```

The script will automatically:
- ✅ Extract boot.img from active slot
- ✅ Copy to PC
- ✅ Install APatch.apk on device
- ✅ Wait for you to patch boot in app
- ✅ Flash patched boot via `dd`
- ✅ Reboot

### Step 2: Manual - Patch Boot in App (⚙️ Not automatable)

When the script pauses and prompts:

1. **On the device physically:**
   - Open **APatch** app
   - Press **"Select boot image"**
   - Select the copied boot.img
   - Press **"Patch"**
   - Wait for completion (2-3 minutes)
   - Press **"OK"** when done

2. **On the PC:**
   - Press **ENTER** in the script when finished

### Step 3: Persistent Installation

When device reboots after flashing:

1. **Open APatch again**
2. **Press "Install"** (Install)
3. Installer will run
4. Press **"OK"**

### Step 4: Final Verification

The script will automatically run:

```bash
adb shell "su -c 'id && echo ROOT_VERIFIED'"
```

If you see `uid=0(root)` → ✅ **Root functional**

### Step 5: Persistence Confirmation

```bash
adb reboot
sleep 60
adb shell "su -c 'id'"
```

If still has `uid=0(root)` after reboot → ✅ **PERSISTENT ROOT - COMPLETED!**

---

## 📝 Automation Script

The script `scripts/setup_apatch.sh` includes:

1. **Requirements verification** (adb, APatch.apk)
2. **boot.img extraction** from device
3. **APatch.apk installation**
4. **Pause for manual patching** (interactive guide)
5. **Automatic flashing** of patched boot with `dd`
6. **Reboot and root verification**

### Manual Usage (Without Script)

If you prefer to do it manually:

```bash
# 1. Extract boot.img
adb root
adb shell "dd if=/dev/block/bootdevice/by-name/boot_b of=/sdcard/boot.img bs=4M"
adb pull /sdcard/boot.img ./

# 2. Install APatch.apk
adb install APatch.apk

# 3. [MANUAL] Open APatch, patch boot.img, save as boot_patched.img

# 4. Flash patched boot
adb push boot_patched.img /data/local/tmp/
adb shell "dd if=/data/local/tmp/boot_patched.img of=/dev/block/bootdevice/by-name/boot_b bs=4M && sync"
adb reboot

# 5. After reboot - Open APatch and press "Install"

# 6. Verify
adb shell "su -c 'id'"
adb reboot
sleep 60
adb shell "su -c 'id'"
```

---

## ⚠️ Troubleshooting

### Problem: `adb: device not found`
- Solution: Enable USB Debugging in Settings > Developer options
- Authorize this computer in device pop-up

### Problem: `dd: permission denied`
- Solution: Run `adb root` before `dd`
- Verify that `adb shell id` shows `uid=0`

### Problem: Device doesn't boot after flashing
- Unlikely but if it happens:
  - Reboot to recovery
  - Flash complete ROM again
  - Go back to Step 0

### Problem: APatch shows "Install" every reboot
- Solution: Press "Install" a second time
- Wait for completion (may take 1-2 minutes)
- Binaries will be copied to `/system/bin/su`

### Problem: Root disappears after reboot
- Solution: APatch requires persistent installation
  - Open APatch after first reboot
  - Press "Install" and wait for completion
  - Reboot again to verify

---

## 🔄 Why This Method?

### Fastboot Limitation (❌ Doesn't Work)

Motorola MBM-3.0 bootloader has `Preflash validation` enabled, which **rejects any modified boot.img** even with:
- ✅ Bootloader unlocked
- ✅ vbmeta disabled  
- ✅ Correctly formed image

Typical error: `Preflash validation failed`

### Solution: `dd` via ADB Root (✅ Works)

Completely bypasses bootloader by writing directly to `/dev/block/mmcblk0p54` without fastboot validation.

**Advantages:**
- Avoids bootloader signature validation
- No soft-brick risks
- Root access from system start
- Applicable to any ROM/kernel on active slot

---

## 📄 License

MIT License - See `LICENSE` for full details.

Use freely, modify and distribute while crediting the original source.

---

## 🙋 Credits

- **APatch**: [bmax121/APatch](https://github.com/bmax121/APatch)
- **LineageOS**: [LineageOS Project](https://lineageos.org)
- **Motorola Moto G8 Plus**: Community XDA-Developers

---

## 📞 Support

For specific issues:
1. Check Troubleshooting above
2. Review logs: `adb shell "logcat -d | grep -i 'apatch\|kpatch\|su'"`
3. Report at [APatch Issues](https://github.com/bmax121/APatch/issues)

---

**Last updated:** January 14, 2026
**Version:** 1.0
**Status:** ✅ Tested and Functional
