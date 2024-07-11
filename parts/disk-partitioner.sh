#!/bin/bash

set -e

# List the available disks

lsblk

# Prompt the user to select a disk

read -r -p "Enter the disk you want to partition (e.g. /dev/sda): " disk

# Check if the disk exists

if [ ! -b "$disk" ]; then
    echo "Error: Disk not found"
    exit 1
fi

# prompt the user to confirm the partitioning

read -r -p "This script will partition your disk. Are you sure? (y/N) " response
case "$response" in
    [yY])
        # Proceed with partitioning
        ;;
    *)
        echo "Aborting..."
        exit 1
        ;;
esac

# Wipe the disk

echo "Wiping the disk..."
sgdisk --zap-all "$disk"

# Create the partitions

echo "Creating partitions..."

sfdisk "$disk" << EOF
label: gpt
name=1: type=ef, size=1G
name=2: type=83, start=, size=\$
EOF

# if command is not successful, exit
if [ $? -ne 0 ]; then
    echo "Error: Failed to create partitions"
    exit 1
fi

# Format the partitions

echo "Formatting partitions..."

mkfs.fat -F32 "${disk}1"
mkfs.btrfs "${disk}2"

# make the btrfs subvolumes

echo "Creating btrfs subvolumes..."

mount "${disk}2" /mnt

cd /mnt

btrfs subvolume create _active
btrfs subvolume create _active/rootvol
btrfs subvolume create _active/homevol
btrfs subvolume create _snapshots
btrfs subvolume create _swap

cd /

umount /mnt

# Mount the partitions

echo "Mounting partitions..."

mount -o noatime,compress=lzo,space_cache,subvol=_active/rootvol "${disk}2" /mnt
mkdir -p /mnt/boot/efi
mkdir /mnt/home
mkdir  -p /mnt/mnt/defvol

mount "${disk}1" /mnt/boot/efi
mount -o noatime,compress=lzo,space_cache,subvol=_active/homevol "${disk}2" /mnt/home
mount -o noatime,compress=lzo,space_cache,subvol=/  "${disk}2" /mnt/mnt/defvol