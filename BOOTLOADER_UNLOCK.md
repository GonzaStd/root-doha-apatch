# Unlocking Motorola Bootloader

*Part of the [root-doha-apatch](https://github.com/GonzaStd/root-doha-apatch) project by [@GonzaStd](https://github.com/GonzaStd)*

Complete guide to unlock the bootloader on Motorola Moto G8 Plus (and other Motorola devices).

## ⚠️ Important Warnings

- **This will WIPE all data on your device**
- **Your warranty may be voided**
- **You can potentially brick your device if something goes wrong**
- **Perform at your own risk**

## Prerequisites

- USB Debugging enabled on device
- `adb` and `fastboot` installed on PC
- USB cable (preferably the original)
- Device battery above 50%
- Internet connection to access Motorola unlock page

## Step 1: Enable OEM Unlocking

1. Go to **Settings > System > Developer options**
2. Scroll down to find **"OEM unlocking"** or **"Allow bootloader unlock"**
3. Toggle it **ON**
4. Confirm any warning dialogs

## Step 2: Get Device Unlock Key

### Get Your Bootloader ID

1. **Connect device to PC via USB**
2. **Enable USB Debugging** if not already enabled
3. **Open terminal/command prompt** and run:

```bash
adb reboot bootloader
```

Device will reboot to fastboot mode. Then run:

```bash
fastboot devices
fastboot getvar serialno
fastboot getvar product
fastboot getvar unlockid
```

**Copy the output of `fastboot getvar unlockid`** - this is your unlock key/token.

### Request Unlock Key from Motorola

1. **Go to:** https://motorola-global-portal.custhelp.com/app/standalone/bootloader-unlock-key-requests
2. **Enter information:**
   - Select your device model (Moto G8 Plus / XT2019-2)
   - Paste your **Unlock ID** from previous step
   - Enter your email address
   - Accept terms and submit

3. **Wait for email** from Motorola (typically within minutes, sometimes hours)
4. **Check spam folder** if not in inbox
5. **Email will contain:**
   - Unlock key (long string of characters)
   - Instructions (usually to use fastboot command)

## Step 3: Unlock Bootloader

1. **Device should still be in fastboot mode** (if rebooted, run `adb reboot bootloader` again)

2. **Run unlock command:**

```bash
fastboot oem unlock <YOUR_UNLOCK_KEY>
```

Replace `<YOUR_UNLOCK_KEY>` with the actual key from Motorola's email.

Example:
```bash
fastboot oem unlock 1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p
```

3. **Device will show warning:** "This will erase all your data"
4. **Press volume up/down to select YES**
5. **Press power button to confirm**
6. Device will wipe all data and reboot
7. Wait for complete wipe (can take 5-10 minutes)

## Step 4: Verify Unlock

```bash
fastboot getvar is-userspace
fastboot getvar is-unlocked
```

You should see:
```
is-unlocked: yes
```

## Step 5: Reboot to System

```bash
fastboot reboot
```

Device will boot to setup screen with erased data.

---

## Automated Script

For your convenience, use the provided script:

```bash
bash scripts/unlock_bootloader.sh
```

This script automates:
- ✅ Checking prerequisites
- ✅ Detecting device in fastboot
- ✅ Extracting bootloader ID
- ✅ Guiding you to Motorola unlock page
- ✅ Waiting for unlock key
- ✅ Performing unlock
- ✅ Verifying success

**Note:** Script cannot automate Motorola's website interaction or email receipt, but will guide you through those steps.

---

## Troubleshooting

### Device not detected in fastboot

```bash
# Restart adb
adb kill-server
adb start-server

# Check connection
adb devices

# Try manual reboot
adb reboot bootloader
```

### "Fastboot not recognized"

Install platform-tools properly:
- Windows: Use zadig or install from Android SDK
- macOS: `brew install android-platform-tools`
- Linux: `sudo apt install android-tools-fastboot`

### "Unknown bootloader variable" error

Some devices may have different variables. Try:
```bash
fastboot oem device-info
```

This will list all available info.

### "flashing_unlock_BL is not allowed"

Your device may have security restrictions. Check:
- OEM unlocking is toggled ON in Developer options
- Device is fully charged
- Try again after 24 hours (Motorola may have cooldown)

### Email from Motorola never arrives

- Check spam/junk folder
- Verify you entered correct email
- Try from different email address
- Wait up to 48 hours

---

## After Unlock

Once bootloader is unlocked:

1. **Device is fully wiped** - no personal data remains
2. **Setup again from beginning** (language, accounts, etc.)
3. **Install custom ROM** (LineageOS or similar)
4. **Install root** (APatch following this guide)

---

## Reverting to Stock (Lock Bootloader)

⚠️ Only if you need to return to stock:

```bash
# Flash official ROM via fastboot
fastboot flash bootloader bootloader.img
fastboot flash system system.img
fastboot flash boot boot.img
# ... etc

# Lock bootloader
fastboot oem lock
```

**Warning:** This is complex and can brick device. Only if you know what you're doing.

---

## References

- Motorola Unlock Portal: https://motorola-global-portal.custhelp.com/app/standalone/bootloader-unlock-key-requests
- Android Fastboot Docs: https://developer.android.com/studio/releases/platform-tools
- Moto G8 Plus XDA: https://xda-developers.com

---

**Last updated:** January 14, 2026
**Version:** 1.0
**Status:** ✅ Tested on Moto G8 Plus
