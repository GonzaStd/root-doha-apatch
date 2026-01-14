# Adapting This Repository for Other Devices

*Part of the [root-doha-apatch](https://github.com/GonzaStd/root-doha-apatch) project by [@GonzaStd](https://github.com/GonzaStd)*

This document explains how to adapt the root installation procedures for other Android devices, particularly Motorola phones.

---

## 🎯 Scope

**This repository is tested for:**
- Device: Motorola Moto G8 Plus (XT2019-2, codename: doha)
- ROM: LineageOS 22.1
- Root Tool: APatch v0.12.2
- Method: ADB root + dd to bypass bootloader Preflash validation

**These procedures MAY work on:**
- Other Motorola devices with similar bootloader
- Devices with LineageOS or similar custom ROMs available
- Devices where direct fastboot is blocked by bootloader validation

**These procedures will NOT work without modification on:**
- Completely different bootloader architectures (Samsung Knox, etc.)
- Devices without custom ROM support
- Devices with different partition layouts
- Completely locked devices without unlock mechanisms

---

## 🔍 Prerequisites for Device Adaptation

### 1. Device Research

Before attempting to adapt this guide:

**Check these resources:**
1. **XDA Developers Thread** - Your device model
   - Look for: Root guides, ROM flashing, bootloader info
   - Check: Boot partition path, unlock process, fastboot limitations
   
2. **LineageOS Wiki** - Is your device supported?
   - Visit: https://wiki.lineageos.org/devices/
   - Find: Download links, partition information, known issues
   
3. **TWRP (Team Win Recovery Project)**
   - Visit: https://twrp.me/devices/
   - Check: Recovery availability for your device
   - Helps: Understand partition structure

4. **Device Documentation**
   - OEM unlock portal (Motorola, Samsung, Xiaomi, etc.)
   - Stock firmware sources
   - Bootloader specifications

### 2. Critical Information to Gather

Before modifying scripts, collect:

| Information | Purpose | How to Get |
|---|---|---|
| **Device Codename** | Branch naming, folder organization | XDA thread, Settings > About > Build |
| **Boot Partition Path** | Replaces `/dev/block/mmcblk0p54` | `adb shell cat /proc/cmdline`, XDA wiki |
| **Bootloader Type** | Determines unlock method | XDA thread, fastboot output |
| **Available Custom ROMs** | Install base before rooting | LineageOS wiki, XDA thread |
| **Active Slot** | A/B partitions vs single slot | `fastboot getvar current-slot` |
| **Preflash Validation** | If fastboot is blocked | Try: `fastboot flash boot boot.img` and check error |

### 3. Verify Device is Compatible

```bash
# Connect device via USB with USB Debugging enabled
# In terminal, run:

# Get device ID
adb shell getprop ro.build.fingerprint

# Get boot partition info
adb shell cat /proc/partitions | grep -i boot

# Get active slot (if A/B device)
fastboot getvar current-slot

# Check for Preflash validation
adb reboot bootloader
fastboot flash boot /tmp/test_boot.img  # Will fail if Preflash is enabled
```

---

## 📋 Adaptation Checklist

### Step 1: Fork Repository

```bash
# Clone this repository
git clone https://github.com/your-username/root-doha-apatch.git
cd root-doha-apatch

# Create new branch for your device
git checkout -b device/motorola-g9
# or: git checkout -b device/samsung-galaxy-a50
# or: git checkout -b device/xiaomi-redmi-note-10
```

### Step 2: Document Device Information

Create a new file: `devices/YOURDEVICE.md`

```markdown
# Device: [Model Name]

- **Codename:** moto-g9 (or similar)
- **Manufacturer:** Motorola (or similar)
- **Bootloader:** MBM-3.0 (or similar)
- **Boot Partition:** /dev/block/mmcblk0p56 (CHANGE IF DIFFERENT)
- **Recovery Partition:** /dev/block/recovery (optional)
- **Supported ROM:** LineageOS 22.1, Android 15
- **Known Issues:** (List any device-specific problems)

## Modifications from doha

1. Boot partition path changed to: /dev/block/mmcblk0p56
2. Unlock process: Use [Device-specific portal]
3. Special considerations: (List any)
```

### Step 3: Identify Boot Partition

**This is critical - wrong partition = brick:**

```bash
# Method 1: From running Android
adb shell cat /proc/cmdline | head -1
# Look for: boot=...mmcblk0p56 or similar

# Method 2: From recovery
adb shell cat /proc/partitions | head -20
# Look for: line with "boot" or first few partitions

# Method 3: From fastboot
adb reboot bootloader
fastboot getvar partition-type:boot
fastboot getvar partition-size:boot
```

**Common boot partition paths:**
- Motorola: `/dev/block/mmcblk0p54` or `/dev/block/mmcblk0p56`
- Samsung: `/dev/block/mmcblk0p##` (varies by model)
- Xiaomi: `/dev/block/mmcblk0p##` (varies by model)
- OnePlus: `/dev/block/mmcblk0p##` (varies by model)

### Step 4: Modify Main Script

Edit `scripts/setup_apatch.sh`:

```bash
# Find this line:
BOOT_PARTITION="/dev/block/mmcblk0p54"

# Change to your device's partition:
BOOT_PARTITION="/dev/block/mmcblk0p56"  # Example for another device

# Also update device detection:
# Find:
DEVICE="doha"

# Change to:
DEVICE="your_codename"
```

### Step 5: Update Documentation

Modify or create device-specific docs:

1. **README.md** - Update prerequisites section
   - Change device model
   - Update ROM download link for your device
   - Note any special requirements

2. **BOOTLOADER_UNLOCK.md** - Update unlock procedure
   - Different manufacturers have different portals
   - Motorola: motorola-global-portal.custhelp.com
   - Samsung: samsung.com/account/find-mobile
   - Xiaomi: mi.com/global (different process)

3. **scripts/unlock_bootloader.sh** - Update for your device
   - Change device detection
   - Update Motorola portal link if different brand
   - Adjust wait times if needed

### Step 6: Test on Device

**IMPORTANT: Test on a device you can afford to brick!**

```bash
# 1. Full fresh install of target ROM
# 2. Enable USB Debugging
# 3. Run modified scripts step-by-step (not automated)

# Test ADB connection
adb devices

# Test getting su access
adb shell su -c "id"  # Should fail (no root yet)

# Test partition access
adb shell su -c "ls -la /dev/block/mmcblk0p56"  # Or your partition

# Verify dd works
adb shell su -c "dd if=/dev/zero of=/dev/null bs=512 count=1"

# Only then: test full APatch installation
```

### Step 7: Commit Changes

```bash
git add -A
git commit -m "Add support for [Device Model] - [Codename]

- Identify boot partition: /dev/block/mmcblk0p56
- Update scripts for device-specific paths
- Add device documentation
- Tested on [Device Model] with [ROM Name]"

# Push to your fork
git push origin device/[codename]
```

### Step 8: Submit Pull Request

1. Push branch to GitHub
2. Create Pull Request with:
   - Device name and codename
   - Partition information used
   - Testing results
   - Any known issues or limitations

---

## ⚠️ Common Pitfalls

### ❌ Wrong Boot Partition = Brick

```bash
# WRONG (from documentation for different device):
adb shell dd if=new_boot.img of=/dev/block/mmcblk0p54

# RIGHT (verify YOUR device's partition first):
adb shell dd if=new_boot.img of=/dev/block/mmcblk0p56  # If this is your partition
```

### ❌ Not Verifying ROM Support

```bash
# Before rooting, verify:
# 1. ROM is stable on your device
# 2. All hardware features work (camera, fingerprint, etc.)
# 3. LineageOS or other custom ROM has official/community builds

# Do NOT attempt on device without proven custom ROM support
```

### ❌ Skipping Bootloader Unlock

```bash
# If bootloader is locked:
# 1. You CANNOT flash modified boot images
# 2. dd method requires system access (which needs root)
# 3. You're in a catch-22 unless ROM supports adb root

# Bootloader MUST be unlocked first
```

### ❌ A/B Partition Confusion

Some devices have A/B boot partitions:

```bash
# Check if your device has A/B partitions:
adb shell cat /proc/cmdline | grep -o 'slot=[ab]'

# If it does:
# - Both slots have boot partitions (boot_a, boot_b)
# - You may need to modify both OR check active slot
# - More complex procedure required

fastboot getvar current-slot
# Response: current-slot: a (or b)

# Only modify active slot:
adb shell dd if=new_boot.img of=/dev/block/by-name/boot_a  # If active is a
```

---

## 🆘 Troubleshooting Device Adaptation

### Issue: Boot Partition Not Found

```bash
# Try these commands:
adb shell df  # Shows mounted filesystems
adb shell mount | grep boot

# Or search partition table:
adb shell cat /proc/partitions

# Or dump partition info:
fastboot getvar all  # From bootloader
```

### Issue: APatch Not Installing on New Device

1. Verify ROM is LineageOS or compatible
2. Check SELinux status: `adb shell getenforce`
3. Verify partition has correct kernel
4. Check APatch version compatibility with Android version

### Issue: Device Not Recognized in Fastboot

```bash
# Verify USB device ID:
fastboot devices

# If empty, try:
# 1. Different USB cable
# 2. Different USB port
# 3. Update fastboot: android-sdk-platform-tools from Google
# 4. Check device in Settings > About > Build #
```

---

## 📚 Useful Resources

- **XDA Developers** - https://xda-developers.com (Device-specific forums)
- **LineageOS Wiki** - https://wiki.lineageos.org (ROM and partition info)
- **TWRP Project** - https://twrp.me (Recovery and partition layouts)
- **AndroidSecurity Blog** - https://android-security.org (Bootloader details)
- **GitHub APatch** - https://github.com/bmax121/APatch (Root tool docs)

---

## 📝 Device Adaptation Template

Use this template for new device additions:

```markdown
# Moto G9 Root Installation

**Device Information:**
- Model: Motorola Moto G9
- Codename: tilapia
- Boot Partition: /dev/block/mmcblk0p56
- Bootloader: MBM-3.0
- Supported ROM: LineageOS 22.1

**Differences from doha (Moto G8 Plus):**
1. Larger partition (1GB vs 512MB)
2. Preflash validation: Also enabled
3. Unlock process: Same Motorola portal

**Status:** ✅ Tested and Working
**Date Tested:** 2026-01-14
**Tested By:** @your-github-username

**Instructions:**
1. Use same procedure as doha
2. Change partition to: `/dev/block/mmcblk0p56`
3. All scripts compatible with this change
```

---

**Remember:** Test thoroughly, document clearly, and contribute back to help other users!
