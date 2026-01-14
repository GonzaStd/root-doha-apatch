#!/bin/bash

#################################################################################
# Unlock Motorola Bootloader for Moto G8 Plus (and other Motorola devices)
# Automates the bootloader unlock process
#
# Usage: bash unlock_bootloader.sh
#################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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
# WARNING
#################################################################################

echo ""
echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  ⚠️  BOOTLOADER UNLOCK WARNING ⚠️                             ║${NC}"
echo -e "${RED}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${RED}║  This will:                                                    ║${NC}"
echo -e "${RED}║  • ERASE all data on your device (no recovery)                ║${NC}"
echo -e "${RED}║  • VOID your warranty                                         ║${NC}"
echo -e "${RED}║  • Potentially BRICK your device if something goes wrong      ║${NC}"
echo -e "${RED}║                                                               ║${NC}"
echo -e "${RED}║  Proceed ONLY if you understand the risks!                   ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "$(echo -e ${YELLOW})Do you understand and accept these risks? (yes/no):${NC} " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_error "Cancelled by user"
    exit 1
fi

#################################################################################
# Check Prerequisites
#################################################################################

print_status "Checking prerequisites..."

# Check fastboot
if ! command -v fastboot &> /dev/null; then
    print_error "fastboot not found. Install Android SDK Platform Tools."
    exit 1
fi
print_success "fastboot available"

# Check adb
if ! command -v adb &> /dev/null; then
    print_error "adb not found. Install Android SDK Platform Tools."
    exit 1
fi
print_success "adb available"

#################################################################################
# Step 1: Reboot to Fastboot
#################################################################################

print_status ""
print_status "STEP 1: Rebooting device to fastboot mode..."
print_status "Make sure USB Debugging is enabled on device!"
echo ""

# Check if device is connected via adb
if ! adb devices 2>/dev/null | grep -q "device"; then
    print_error "Device not connected or USB Debugging not enabled"
    print_status "Enable USB Debugging: Settings > Developer options > USB Debugging"
    exit 1
fi

adb reboot bootloader
print_status "Waiting for fastboot mode..."
sleep 5

# Verify fastboot connection
if ! fastboot devices | grep -q "fastboot"; then
    print_error "Device not detected in fastboot mode"
    print_status "Try manually rebooting to fastboot and run:"
    print_status "  fastboot devices"
    exit 1
fi

DEVICE_ID=$(fastboot devices | head -1 | awk '{print $1}')
print_success "Device in fastboot: $DEVICE_ID"

#################################################################################
# Step 2: Get Device Info
#################################################################################

print_status ""
print_status "STEP 2: Retrieving device information..."

SERIAL=$(fastboot getvar serialno 2>&1 | grep "serialno" | awk '{print $2}')
PRODUCT=$(fastboot getvar product 2>&1 | grep "product" | awk '{print $2}')
UNLOCKID=$(fastboot getvar unlockid 2>&1 | grep "unlockid" | awk '{print $2}')

print_success "Serial number: $SERIAL"
print_success "Product: $PRODUCT"
print_success "Unlock ID: $UNLOCKID"

echo ""
echo -e "${YELLOW}SAVE THIS UNLOCK ID:${NC} ${GREEN}$UNLOCKID${NC}"
echo ""

#################################################################################
# Step 3: Get Unlock Key from Motorola
#################################################################################

print_warning ""
print_status "STEP 3: Get unlock key from Motorola"
print_status "=========================================="
echo ""
echo "1. Go to: https://motorola-global-portal.custhelp.com/app/standalone/bootloader-unlock-key-requests"
echo ""
echo "2. Fill in:"
echo "   - Device: Moto G8 Plus (or your device)"
echo "   - Unlock ID: ${GREEN}$UNLOCKID${NC}"
echo "   - Email: (your email)"
echo ""
echo "3. Submit and check your email for unlock key"
echo ""
echo "4. Unlock key format: long string of characters"
echo "   Example: 1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p"
echo ""
echo -e "${YELLOW}Keep this window open and come back here when you have the unlock key${NC}"
echo ""

read -p "$(echo -e ${BLUE})[Press ENTER when you have the unlock key]${NC} " -r

read -p "$(echo -e ${BLUE})Enter your unlock key: ${NC}" -r UNLOCK_KEY

if [ -z "$UNLOCK_KEY" ]; then
    print_error "No unlock key provided"
    exit 1
fi

print_success "Unlock key received: ${UNLOCK_KEY:0:8}...${UNLOCK_KEY: -8}"

#################################################################################
# Step 4: Verify Device Still in Fastboot
#################################################################################

print_status ""
print_status "STEP 4: Verifying device connection..."

if ! fastboot devices | grep -q "fastboot"; then
    print_error "Device disconnected from fastboot"
    print_status "Reconnect device and run:"
    print_status "  adb reboot bootloader"
    exit 1
fi

print_success "Device still in fastboot mode"

#################################################################################
# Step 5: Perform Unlock
#################################################################################

print_warning ""
print_status "STEP 5: Unlocking bootloader..."
print_warning "This will ERASE all device data!"
print_status "=========================================="
echo ""
echo "Your device will show: 'This will erase all your data'"
echo "Choose YES using volume keys"
echo "Confirm with power button"
echo ""

read -p "$(echo -e ${YELLOW})Ready? Press ENTER to proceed (or Ctrl+C to cancel)${NC} " -r

print_status "Sending unlock command..."
fastboot oem unlock "$UNLOCK_KEY"

print_status "Device is wiping data and unlocking..."
print_status "This can take 5-10 minutes..."
sleep 30

# Try to detect reboot
for i in {1..60}; do
    if adb devices 2>/dev/null | grep -q "device"; then
        print_success "Device rebooted successfully"
        break
    fi
    sleep 2
done

#################################################################################
# Step 6: Verify Unlock
#################################################################################

print_status ""
print_status "STEP 6: Verifying bootloader is unlocked..."

sleep 5

# Reboot to fastboot to check status
adb reboot bootloader 2>/dev/null || true
sleep 5

if fastboot devices | grep -q "fastboot"; then
    IS_UNLOCKED=$(fastboot getvar is-unlocked 2>&1 | grep "is-unlocked" || echo "unknown")
    print_success "Bootloader status: $IS_UNLOCKED"
    
    if [[ "$IS_UNLOCKED" == *"yes"* ]]; then
        print_success "✓✓✓ BOOTLOADER SUCCESSFULLY UNLOCKED ✓✓✓"
    else
        print_warning "Could not verify unlock status"
    fi
fi

#################################################################################
# Step 7: Final Reboot
#################################################################################

print_status ""
print_status "STEP 7: Final reboot..."

fastboot reboot
print_status "Device rebooting..."
sleep 30

if adb devices | grep -q "device"; then
    print_success "Device rebooted to Android"
else
    print_status "Device rebooting, waiting..."
    sleep 30
fi

#################################################################################
# Complete
#################################################################################

print_success ""
print_success "=========================================="
print_success "BOOTLOADER UNLOCK COMPLETE!"
print_success "=========================================="
echo ""
echo "Next steps:"
echo "1. Complete initial setup on device"
echo "2. Enable USB Debugging again"
echo "3. Install custom ROM (LineageOS recommended)"
echo "4. Install root with: bash scripts/setup_apatch.sh"
echo ""
