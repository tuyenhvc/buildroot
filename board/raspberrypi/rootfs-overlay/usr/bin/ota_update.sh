#!/bin/sh
# OTA Update Agent (A/B Partitioning)

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_new_rootfs.ext4>"
  exit 1
fi

IMAGE_FILE=$1
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Error: File $IMAGE_FILE not found!"
  exit 1
fi

ACTIVE_SLOT=$(fw_printenv -n active_slot 2>/dev/null)
if [ -z "$ACTIVE_SLOT" ]; then
  ACTIVE_SLOT="a"
fi

echo "Current active slot: $ACTIVE_SLOT"

if [ "$ACTIVE_SLOT" = "a" ]; then
  TARGET_SLOT="b"
  TARGET_PART="/dev/mmcblk0p3"
else
  TARGET_SLOT="a"
  TARGET_PART="/dev/mmcblk0p2"
fi

echo "Flashing $IMAGE_FILE to $TARGET_PART (Slot $TARGET_SLOT)..."
dd if="$IMAGE_FILE" of="$TARGET_PART" bs=4M conv=fsync

if [ $? -eq 0 ]; then
  echo "Flash successful!"
  echo "Updating U-Boot environment..."
  fw_setenv active_slot $TARGET_SLOT
  fw_setenv boot_tries 3
  echo "Update complete. Slot $TARGET_SLOT will be active on next reboot."
else
  echo "Error during flash. Update aborted."
  exit 1
fi
