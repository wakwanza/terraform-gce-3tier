#!/bin/bash
# Mount and format the disks
sudo mkdir -p /data
sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /data
sudo echo "Mount persists"
sudo sh -c "echo \"/dev/sdb   /data   ext4   noatime,data=writeback,errors=remount-ro   0 1\" >> /etc/fstab"
sudo echo "fstab done"
