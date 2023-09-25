#!/bin/bash

set -euo pipefail

# Generic script to install Amazon FSx Lustre client on Ubuntu AMI. Run this as root, then reboot.

: "${EFS_DNS:=fsx_file_system_dns_name}"
: "${EFS_MOUNTDIR:=/mnt/efs}"


################################################################################
# 000: Sanity check the Ubuntu version
################################################################################
[[ $EUID -ne 0 ]] && { echo 'Script is NOT run as root. Exiting...' ; exit -1 ; }
[[ ! $(lsb_release -is) =~ "Ubuntu" ]] && { echo "This script is for Ubuntu only. Exiting..." ; exit -1 ; }

if [[ -t 1 ]]; then
    COLOR_RED="\033[1;31m"
    COLOR_GREEN="\033[1;32m"
    COLOR_YELLOW="\033[1;33m"
    COLOR_OFF="\033[0m"
else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_OFF=""
fi

declare -a SUPPORTED_UBUNTU=( 20.04 22.04 )
if [[ ! " ${SUPPORTED_UBUNTU[*]} " =~ " $(lsb_release -rs) " ]]; then
    echo -e "${COLOR_YELLOW}WARNING: Ubuntu-$(lsb_release -rs) not in supported versions. Script may break.${COLOR_OFF}

Supported Ubuntu versions: [$(echo ${SUPPORTED_UBUNTU[@]} | sed 's/ /, /g')].
"
fi


################################################################################
# 010: Here we go...
################################################################################
# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

pushd /opt
git clone https://github.com/aws/efs-utils
pushd efs-utils
./build-deb.sh
apt-get -y install ./build/amazon-efs-utils*deb
popd ; popd

################################################################################
# 020: Extra yard: patch /etc/fstab with Lustre.
################################################################################
# Add template entry for usability
[[ $(grep "^# EFS_DNS_NAME:" /etc/fstab 2> /dev/null) ]] \
    || echo \
        "# EFS_DNS_NAME:/ <LOCAL_MOUNT_DIR> efs _netdev,noresvport,tls 0 0" \
        >> /etc/fstab

if [[ ! $EFS_DNS =~ "efs_file_system_dns_name" ]]; then
    # Comment out any old entry.
    sed -i "s|^\([^#].* $EFS_MOUNTDIR efs .*$\)|#\1|g" /etc/fstab

    # Add entry for the specific volume
    echo "$EFS_DNS:/ $EFS_MOUNTDIR efs _netdev,noresvport,tls 0 0" >> /etc/fstab
    mkdir -p ${EFS_MOUNTDIR}/
    cat /etc/fstab

    mount ${EFS_MOUNTDIR}
fi
