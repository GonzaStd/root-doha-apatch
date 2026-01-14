#!/bin/bash

#################################################################################
# Setup APatch Root for Motorola G8 Plus (doha)
# Automates APatch installation with boot patching via dd
#
# Usage: bash setup_apatch.sh
#################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print with color
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

ask_continue() {
    read -p "$(echo -e ${BLUE})[Press ENTER to continue]${NC} " -r
}

#################################################################################
# Pre-flight checks
#################################################################################

print_status "Checking requirements..."

# Check adb
if ! command -v adb &> /dev/null; then
    print_error "adb not found. Install Android SDK Platform Tools."
    exit 1
fi
print_success "adb available"

# Check APatch.apk
if [ ! -f "APatch.apk" ]; then
    print_error "APatch.apk not found in current folder"
    print_status "Download from: https://github.com/bmax121/APatch/releases"
    exit 1
fi
print_success "APatch.apk found"

# Check ADB connection
if ! adb devices | grep -q "device"; then
    print_error "Device not connected or USB Debugging not enabled"
    print_status "Steps:"
    print_status "1. Enable USB Debugging in Settings > Developer options"
    print_status "2. Authorize this computer in device pop-up"
    print_status "3. Run this script again"
    exit 1
fi
print_success "Device connected"

DEVICE_SERIAL=$(adb devices | grep -E "^[A-Z0-9]+\s+device$" | awk '{print $1}')
print_success "Device: $DEVICE_SERIAL"

#################################################################################
# STEP 1: Extract boot.img
#################################################################################

print_status "STEP 1: Extracting boot.img from device..."

# Detect active slot
SLOT=$(adb shell "getprop ro.boot.slot_suffix" | tr -d '\r')
print_status "Active slot: $SLOT"

# Slot to partition mapping
if [ "$SLOT" = "_a" ]; then
    BOOT_PARTITION="/dev/block/bootdevice/by-name/boot_a"
    BOOT_PARTITION_NUM="53"
elif [ "$SLOT" = "_b" ]; then
    BOOT_PARTITION="/dev/block/bootdevice/by-name/boot_b"
    BOOT_PARTITION_NUM="54"
else
    print_error "Unknown slot: $SLOT"
    exit 1
fi

# Enable ADB root
print_status "Enabling ADB root..."
adb root > /dev/null 2>&1 || true
sleep 2

# Verify root
if ! adb shell "id" | grep -q "uid=0"; then
    print_error "Failed to obtain root permissions in ADB"
    exit 1
fi
print_success "ADB root enabled"

# Extract boot.img
BOOT_FILE="boot${SLOT}.img"
print_status "Extracting boot.img from $BOOT_PARTITION..."
adb shell "dd if=$BOOT_PARTITION of=/data/local/tmp/boot.img bs=4M" > /dev/null 2>&1
adb pull /data/local/tmp/boot.img "$BOOT_FILE" > /dev/null
adb shell "rm /data/local/tmp/boot.img" > /dev/null 2>&1

if [ ! -f "$BOOT_FILE" ]; then
    print_error "Failed to extract boot.img"
    exit 1
fi

FILE_SIZE=$(du -h "$BOOT_FILE" | cut -f1)
print_success "boot.img extracted: $BOOT_FILE ($FILE_SIZE)"

#################################################################################
# STEP 2: Install APatch.apk
#################################################################################

print_status "STEP 2: Installing APatch.apk..."

if adb install APatch.apk | grep -q "Success"; then
    print_success "APatch.apk installed"
else
    print_warning "APatch.apk was already installed"
fi

sleep 2

#################################################################################
# STEP 3: MANUAL - Patch boot in app (Not automatable)
#################################################################################

print_warning "STEP 3: Manual Patching Required"
print_status "=========================================="
echo ""
echo -e "${YELLOW}Follow these steps ON THE DEVICE PHYSICALLY:${NC}"
echo ""
echo "1. Open ${BLUE}APatch${NC} app"
echo "2. On main screen, press ${BLUE}'Select boot image'${NC}"
echo "3. Select: ${YELLOW}$BOOT_FILE${NC}"
echo "4. Press ${BLUE}'Patch'${NC} and wait (2-3 minutes)"
echo "5. When done, press ${BLUE}'OK'${NC}"
echo "6. App will show: ${GREEN}'Boot image patched successfully'${NC}"
echo "7. Save/export patched boot if needed"
echo ""
print_status "Come back here when finished on device"
echo ""
ask_continue

#################################################################################
# STEP 4: Copy and flash patched boot
#################################################################################

print_status "STEP 4: Extracting patched boot from device..."

# APatch typically saves to /data/adb/ap/backup/
# Or can be in /sdcard/ or /data/
# Try to find it

PATCHED_BOOT_CANDIDATES=(
    "/data/adb/ap/backup/boot.img"
    "/data/adb/ap/backup/boot_patched.img"
    "/sdcard/Documents/boot.img"
    "/sdcard/boot_patched.img"
    "/data/local/tmp/boot_patched.img"
)

PATCHED_BOOT_PATH=""
for path in "${PATCHED_BOOT_CANDIDATES[@]}"; do
    if adb shell "[ -f '$path' ]" 2>/dev/null; then
        PATCHED_BOOT_PATH="$path"
        print_success "Patched boot found: $path"
        break
    fi
done

if [ -z "$PATCHED_BOOT_PATH" ]; then
    print_error "No patched boot found on device"
    print_status "Expected locations:"
    for path in "${PATCHED_BOOT_CANDIDATES[@]}"; do
        print_status "  - $path"
    done
    print_status "Try exporting manually from APatch and run:"
    print_status "  adb pull <path_on_device> boot_patched.img"
    exit 1
fi

# Copy patched boot
adb pull "$PATCHED_BOOT_PATH" "boot_patched_${SLOT}.img" > /dev/null
print_success "Patched boot copied: boot_patched_${SLOT}.img"

# Copy to device for flashing
adb push "boot_patched_${SLOT}.img" /data/local/tmp/boot_patched.img > /dev/null 2>&1
print_success "Patched boot copied to device"

#################################################################################
# STEP 5: Flash patched boot with dd
#################################################################################

print_status "STEP 5: Flashing patched boot..."

if ! adb shell "dd if=/data/local/tmp/boot_patched.img of=/dev/block/mmcblk0p${BOOT_PARTITION_NUM} bs=4M && sync" > /dev/null 2>&1; then
    print_error "Error flashing boot"
    exit 1
fi

print_success "Patched boot flashed successfully"

# Cleanup
adb shell "rm /data/local/tmp/boot_patched.img" > /dev/null 2>&1

#################################################################################
# STEP 6: Reboot
#################################################################################

print_status "STEP 6: Rebooting device..."
adb reboot

print_status "Waiting for device (60 seconds)..."
sleep 60

if ! adb devices | grep -q "device"; then
    print_warning "Device not connected yet, waiting more..."
    sleep 30
fi

if ! adb devices | grep -q "device"; then
    print_error "Device did not connect after reboot"
    exit 1
fi

print_success "Device rebooted successfully"

#################################################################################
# STEP 7: MANUAL - Install APatch persistently
#################################################################################

print_warning "STEP 7: Persistent Installation (Manual)"
print_status "=========================================="
echo ""
echo -e "${YELLOW}ON THE DEVICE:${NC}"
echo ""
echo "1. Open ${BLUE}APatch${NC} app again"
echo "2. Press ${BLUE}'Install'${NC} (Install)"
echo "3. Press ${BLUE}'OK'${NC} and wait for completion (1-2 minutes)"
echo "4. You'll see installation messages"
echo "5. When done, press ${BLUE}'OK'${NC}"
echo ""
print_status "Come back here when finished"
echo ""
ask_continue

#################################################################################
# STEP 8: Verify root
#################################################################################

print_status "STEP 8: Verifying root..."

# Enable ADB root if needed
adb root > /dev/null 2>&1 || true
sleep 2

if adb shell "su -c 'id'" | grep -q "uid=0(root)"; then
    print_success "ROOT FUNCTIONAL ✓"
else
    print_error "Root not available"
    exit 1
fi

#################################################################################
# STEP 9: Verify persistence (Final reboot)
#################################################################################

print_status "STEP 9: Verifying persistence..."
print_status "Rebooting device..."

adb reboot
print_status "Waiting for device (60 seconds)..."
sleep 60

if ! adb devices | grep -q "device"; then
    print_warning "Device not connected, waiting more..."
    sleep 30
fi

# Verify root after reboot
if adb shell "su -c 'id'" 2>/dev/null | grep -q "uid=0(root)"; then
    print_success "PERSISTENT ROOT ✓✓✓"
    echo ""
    print_success "=========================================="
    print_success "ROOT INSTALLATION COMPLETED SUCCESSFULLY!"
    print_success "=========================================="
    echo ""
    adb shell "su -c 'id'"
else
    print_error "Root NOT persistent after reboot"
    print_status "Try opening APatch again and pressing 'Install'"
    exit 1
fi

print_success "Installation finished"
