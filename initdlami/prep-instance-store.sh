#!/bin/bash

# Based on https://gist.github.com/fideloper/40f7807920aa1198fa07b9e69dc82b56
# Require: sudo yum install -y nvme-cli
declare -a EPHEMERAL_DISK=(`sudo nvme list | grep 'Amazon EC2 NVMe Instance Storage' | awk '{ print $1 }'`)

COUNT=${#EPHEMERAL_DISK[@]}
case $COUNT in
    0)
        echo No instance store...
        exit 0
        ;;
    1)
        echo Creating xfs filesystem...
        DEV=${EPHEMERAL_DISK[0]}
        ;;
    *)
        echo Creating raid-0...
        DEV=/dev/md0
        sudo mdadm --create --verbose /dev/md0 --level=0 --name=MY_RAID --raid-devices=$COUNT ${EPHEMERAL_DISK[@]}
esac

sudo mkfs -t xfs $DEV
sudo mount $DEV /mnt
sudo mkdir -p /mnt/scratch
sudo chown -R ec2-user:ec2-user /mnt/scratch/
df -hT
lsblk

echo "On an instance with 1+ instance stores, run below after start-up or reboot:

    ~/initdlami/prep-instance-store.sh
" > ~/PREP_INSTANCE_STORE.txt