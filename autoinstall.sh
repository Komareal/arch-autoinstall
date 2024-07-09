
#!/bin/bash
# Set the keyboard layout to US
loadkeys us

# test the internet connection

if [[ $(ping -c 1 archlinux.org) ]]; then
  echo "Internet connection is working fine. Proceeding with the installation"
else
  echo "Internet connection is not working. Please check your connection"
  exit 1
fi

# Update the system clock
timedatectl set-ntp true

# Partition the disk
 
 if [[ $(./parts/disk-partitioner.sh) ]]; then
   echo "Disk partitioning completed successfully"
 else
   echo "Disk partitioning failed. Exiting..."
   exit 1
 fi