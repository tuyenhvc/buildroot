#!/bin/sh
# OTA Update Agent (A/B Partitioning)

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_ota_update_full.tar>"
  exit 1
fi

OTA_PACKAGE=$1
if [ ! -f "$OTA_PACKAGE" ]; then
  echo "Error: File $OTA_PACKAGE not found!"
  exit 1
fi

echo "Extracting OTA package to /tmp/ota_temp..."
rm -rf /tmp/ota_temp
mkdir -p /tmp/ota_temp
tar -xf "$OTA_PACKAGE" -C /tmp/ota_temp

IMAGE_FILE="/tmp/ota_temp/rootfs.ext4.gz"
BMAP_FILE="/tmp/ota_temp/rootfs.ext4.bmap"

if [ ! -f "$IMAGE_FILE" ]; then
  echo "Error: Extracted file rootfs.ext4.gz not found in the package!"
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

echo "Flashing $IMAGE_FILE to $TARGET_PART (Slot $TARGET_SLOT) using bmaptool..."
if [ -n "$BMAP_FILE" ] && [ -f "$BMAP_FILE" ]; then
  bmaptool copy "$IMAGE_FILE" "$TARGET_PART" --bmap "$BMAP_FILE"
else
  echo "No bmap file provided or found, using bmaptool without bmap (still handles decompression)..."
  bmaptool copy "$IMAGE_FILE" "$TARGET_PART"
fi

if [ $? -eq 0 ]; then
  echo "Flash successful!"
  echo "Updating U-Boot environment..."
  fw_setenv active_slot $TARGET_SLOT
  fw_setenv boot_tries 3
  echo "Update complete. Slot $TARGET_SLOT will be active on next reboot."
  rm -rf /tmp/ota_temp
else
  echo "Error during flash. Update aborted."
  rm -rf /tmp/ota_temp
  exit 1
fi
