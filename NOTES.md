# Technical Notes - Root Doha APatch

## Implementation Details

### Target Device
- **Model:** Motorola Moto G8 Plus
- **Codename:** doha
- **SKU:** XT2019-2
- **Bootloader:** MBM-3.0-doha_retail-f9b10e522bd-210802

### Target ROM
- **OS:** LineageOS 22.1
- **Android:** Android 15 (API 35)
- **Build:** 2025-03-18 (UNOFFICIAL-amogus_doha)
- **Kernel:** Linux 4.14.190+ with SELinux

### Root Tool
- **Tool:** APatch
- **Version:** v0.12.2 (build 11142)
- **Repository:** https://github.com/bmax121/APatch
- **License:** GPL-3.0

### Method: Why `dd` and not fastboot?

#### Fastboot Limitation (❌ DOESN'T WORK)

Motorola MBM-3.0 bootloader implements `Preflash validation` that:
- Verifies boot.img signature **BEFORE** flashing
- Rejects any modified image
- Cannot be disabled even with unlocked bootloader

**Evidence:**
```
fastboot flash boot_b apatch_patched.img
target reported max download size of 536870912 bytes
sending 'boot_b' (65536 KB)...
OKAY [  2.234s]
writing 'boot_b'...
Preflash validation failed
FAILED (remote failure)
fastboot: error: Command failed
```

#### Solution: `dd` via ADB Root (✅ WORKS)

**Flow:**
1. `adb root` → Get root access in ADB
2. `adb shell dd if=boot_patched.img of=/dev/block/mmcblk0p54` → Write directly
3. Completely bypasses bootloader validation
4. Boots normally with patched kernel

**Advantages:**
- Avoids signature validation
- No bootloader interaction
- Immediate root access
- Applicable to custom ROMs

### Installation Flow

```
┌─────────────────────────────┐
│ Clean ROM (LineageOS 22.1)  │
└──────────────┬──────────────┘
               │
               ▼
      ┌────────────────┐
      │ Enable ADB +   │
      │ Superuser      │
      └────────┬───────┘
               │
               ▼
      ┌──────────────────────┐
      │ Extract boot.img     │
      │ (from active slot)   │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ Install APatch.apk   │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ [MANUAL]             │
      │ Patch boot in app    │
      │ APatch selects       │
      │ boot.img and patches │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ Flash with dd:       │
      │ /data/local/tmp/... →│
      │ /dev/block/mmcblk... │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ Reboot with patched  │
      │ boot in slot         │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ [MANUAL]             │
      │ APatch "Install"     │
      │ Install su binary    │
      └────────┬─────────────┘
               │
               ▼
      ┌──────────────────────┐
      │ ✓ ROOT FUNCTIONAL    │
      │ ✓ ROOT PERSISTENT    │
      └──────────────────────┘
```

### Device Partitions

```
Partition   | Number | Function
------------|--------|-------------------
boot_a      | p53    | Kernel + Ramdisk A
boot_b      | p54    | Kernel + Ramdisk B
system      | p37/71 | System (A/B)
vendor      | p38/72 | Vendor (A/B)
product     | p39/73 | Product (A/B)
...         | ...    | Data, cache, etc
```

**Note:** Moto G8 Plus uses **dual-slot A/B**, need to detect active slot with:
```bash
adb shell "getprop ro.boot.slot_suffix"  # Returns "_a" or "_b"
```

### Generated Files

During installation, created:
- `boot_a.img` or `boot_b.img` - Original extracted boot
- `boot_patched_a.img` or `boot_patched_b.img` - Patched boot

### Binaries Installed by APatch

```
/system/bin/su                 - su binary for root
/data/adb/ap/bin/apd           - APatch daemon
/data/adb/ap/bin/magiskboot    - Boot tool
/data/adb/ap/bin/magiskpolicy  - SELinux policy
```

### SELinux Context

- **Before:** `u:r:init:s0` (init context)
- **After:** `u:r:magisk:s0` (APatch uses Magisk context for compatibility)

### Useful Logs

**Verify kernel patch loaded:**
```bash
adb shell "dmesg | grep -i 'kpatch\|apatch'"
```

**Verify su binaries:**
```bash
adb shell "which su && su -c 'id'"
```

**Recovery log (if needed):**
```bash
adb shell "cat /tmp/recovery.log"
```

### Known Limitations

1. **APatch requires manual install on first reboot**
   - Solution: Press "Install" in app after first reboot

2. **Bootloader MBM-3.0 rejects fastboot**
   - Solution: Use direct `dd` via ADB root

3. **ROM must be OTA-updatable**
   - LineageOS 22.1 supports OTA correctly
   - APatch preserves OTA capability

### Testing Performed ✓

- ✓ Device boots normally with patched kernel
- ✓ Root functional immediately post-patch
- ✓ Root persists after multiple reboots
- ✓ APatch app reports "Installed" correctly
- ✓ `su -c 'id'` returns expected uid=0(root)
- ✓ Correct SELinux context: `u:r:magisk:s0`
- ✓ LineageOS ROM intact, no corruption
- ✓ Recoverable if fails (back to fastboot + ROM)

### Evaluated Alternatives ❌

1. **Fastboot flash** - Rejected by Preflash validation
2. **Recovery flashable ZIP** - Signature verification failed
3. **Magisk** - Same fastboot issues
4. **KernelSU** - Not compiled in LineageOS kernel
5. **Classic Superuser.apk** - Requires kernel compilation

### Conclusion

The `adb root + dd` method is the **only viable solution** for this device/ROM due to Motorola MBM-3.0 bootloader restrictions.

---

**Last updated:** 2026-01-14
**Version:** 1.0
**Author:** root-doha-apatch contributors
