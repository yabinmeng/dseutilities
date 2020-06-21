#! /bin/bash
DISCOVERY_FOLDER=/mnt/disks
sudo mkdir -p $DISCOVERY_FOLDER

sudo dd if=/dev/zero of=/root/myloopbackfile.img bs=100M count=10
sudo du -sh /root/myloopbackfile.img
echo
sudo losetup -fP /root/myloopbackfile.img
LOOP_DEVICE=`sudo losetup -a | awk -F ':' '{print $1}'`
echo
sudo mkfs.ext4 $LOOP_DEVICE
echo
DISK_UUID=`sudo blkid -s UUID -o value $LOOP_DEVICE`
PV_MNT_FOLDER=$DISCOVERY_FOLDER/$DISK_UUID
sudo mkdir $PV_MNT_FOLDER
sudo mount -t ext4 $LOOP_DEVICE $PV_MNT_FOLDER