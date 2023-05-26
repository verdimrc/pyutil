#!/bin/bash

set -xeo pipefail

# Undo lvm in newer DLAMI: Deep Learning Base GPU AMI (Ubuntu 20.04) 20230519).
if [[ $(mount | grep '\/opt\/dlami\/nvme') ]]; then
    systemctl stop dlami-nvme
    systemctl disable dlami-nvme

    # See: /opt/aws/dlami/bin/nvme_ephemeral_drives.sh
    # /dev/mapper/vg.01-lv_ephemeral
    LVM_PATH=$(mount | grep \/opt\/dlami\/nvme | cut -d' ' -f1)
    if [[ $(lvs $LVM_PATH --nosuffix --noheadings -q) ]]; then
        umount /opt/dlami/nvme
        lvchange -an $LVM_PATH
        lvremove -y $LVM_PATH
    fi
fi

# Based on https://gist.github.com/fideloper/40f7807920aa1198fa07b9e69dc82b56
# Require: sudo yum install -y nvme-cli
declare -a EPHEMERAL_DISK=(`sudo nvme list | grep 'Amazon EC2 NVMe Instance Storage' | awk '{ print $1 }'`)

COUNT=${#EPHEMERAL_DISK[@]}
TO_FORMAT=0
case $COUNT in
    0)
        echo No instance store...
        exit 0
        ;;
    1)
        DEV=${EPHEMERAL_DISK[0]}

        # In case this script is rerun.
        [[ $(mount | grep "$DEV on \/mnt type xfs ") ]] && exit 0

        # Instance is rebooted.
        lsblk -f $DEV --noheadings | grep xfs
        [[ $? -eq 0 ]] || TO_FORMAT=1
        ;;
    *)
        # In case this script is rerun.
        [[ $(mount | grep '^\/dev\/md[0-9][0-9]* on \/mnt type xfs ') ]] && exit 0

        if [[ ! -e /dev/md/MY_RAID ]]; then
            # Instance is (re)started.
            echo Creating raid-0...
            DEV=/dev/md0
            mdadm --create --verbose /dev/md0 --level=0 --name=MY_RAID --raid-devices=$COUNT ${EPHEMERAL_DISK[@]}
            TO_FORMAT=1
        else
            # Instance is rebooted.
            DEV=/dev/md/MY_RAID
        fi
esac

[[ $TO_FORMAT -eq 1 ]] && { echo Creating xfs filesystem... ; mkfs.xfs -f -K $DEV ; }
mount $DEV /mnt
mkdir -p /mnt/scratch
chown ubuntu:ubuntu /mnt/scratch/
df -hT
lsblk
