#!/bin/bash

# 1. Create an empty disk image of appropriate size (adjust size as needed)
dd if=/dev/zero of=mkosi.builddir/azure_image.raw bs=1M count=512

# 2. Set up partition table with an EFI System Partition
parted mkosi.builddir/azure_image.raw --script -- \
  mklabel gpt \
  mkpart ESP fat32 1MiB 100% \
  set 1 boot on

# 3. Set up a loop device to access the image
LOOPDEV=$(sudo losetup --partscan --find --show mkosi.builddir/azure_image.raw)

# 4. Format the ESP partition
sudo mkfs.fat -F32 ${LOOPDEV}p1

# 5. Mount the partition
ESP_MOUNT="mkosi.builddir/esp_mount"
mkdir -p "${ESP_MOUNT}"
sudo mount ${LOOPDEV}p1 "${ESP_MOUNT}"

# 6. Create EFI directory structure and copy the UKI file
sudo mkdir -p "${ESP_MOUNT}/EFI/BOOT"
sudo cp build/tdx-debian.efi "${ESP_MOUNT}/EFI/BOOT/BOOTX64.EFI"

# 7. Unmount and detach
sudo umount "${ESP_MOUNT}"
sudo losetup -d ${LOOPDEV}
rmdir "${ESP_MOUNT}"

# 8. Convert to VHD
qemu-img convert -O vpc -o subformat=fixed,force_size "mkosi.builddir/azure_image.raw" build/tdx-debian.vhd
rm -r mkosi.builddir/azure_image.raw