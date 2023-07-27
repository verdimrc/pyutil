#!/bin/bash

set -euo pipefail

# Generic script to install Amazon FSx Lustre client on Ubuntu AMI. Run this as root, then reboot.

: "${FSX_DNS:=fsx_file_system_dns_name}"
: "${FSX_MOUNTNAME:=fsx_mountname}"
: "${FSX_MOUNTDIR:=/mnt/fsx}"


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
wget -O - https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc | gpg --dearmor > /usr/share/keyrings/fsx-ubuntu-public-key.gpg
echo "deb [signed-by=/usr/share/keyrings/fsx-ubuntu-public-key.gpg] https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/fsxlustreclientrepo.list

# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive
apt update

# These meta-package sometimes breaks apt dependencies, or upgrades the kernel newer than the
# available lustre-client-modules-*-aws.
apt remove -y --allow-change-held-packages linux-aws linux-image-aws linux-headers-aws || true

apt upgrade -y

PKGS+=(
    awscli lustre-client-modules-aws
)
# echo "${PKGS[@]}"
apt install -y "${PKGS[@]}"

# Install matching kernel
INSTALLED_LUSTRE_CLIENT=$(dpkg --get-selections | grep -v "deinstall" | cut -f1 | grep lustre-client-modules-.*-aws | sort -n | tail -1)
if [[ $? == 0 ]]; then
    LUSTRE_KERNEL_AWS=${INSTALLED_LUSTRE_CLIENT#lustre-client-modules-*}   # 5.15.0-1034-aws
    LUSTRE_KERNEL=${LUSTRE_KERNEL_AWS%*-aws}                               # 5.15.0-1034
    declare -a KERNEL_PKGS=(
        lustre-client-modules-${LUSTRE_KERNEL}-aws
        $(apt-cache search linux-aws | grep headers-${LUSTRE_KERNEL} | cut -d' ' -f1)
        linux-headers-${LUSTRE_KERNEL}-aws
        linux-image-${LUSTRE_KERNEL}-aws
        linux-modules-${LUSTRE_KERNEL}-aws
    )
    apt install -y "${KERNEL_PKGS[@]}"

    # Lock grub to Lustre's kernel.
    sed -i \
        "s/^GRUB_DEFAULT=.*$/GRUB_DEFAULT='Advanced options for Ubuntu>Ubuntu, with Linux $LUSTRE_KERNEL_AWS'/g" \
        /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi


################################################################################
# 020: Extra yard: patch /etc/fstab with Lustre.
################################################################################
[[ $(lsb_release -rs) < 22.04 ]] && REQUIRES_SVC=network.service || REQUIRES_SVC=systemd-networkd-wait-online.service

# Add template entry for usability
[[ $(grep "^# FSX_DNS_NAME@tcp:" /etc/fstab 2> /dev/null) ]] \
    || echo \
        "# FSX_DNS_NAME@tcp:/FSX_MOUNT_NAME <LOCAL_MOUNT_DIR> lustre defaults,nofail,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=${REQUIRES_SVC} 0 0" \
        >> /etc/fstab

if [[ ! $FSX_DNS =~ "fsx_file_system_dns_name" ]]; then
    # Comment out any old entry.
    sed -i "s|^\([^#].* $FSX_MOUNTDIR lustre .*$\)|#\1|g" /etc/fstab

    # Add entry for the specific volume
    echo "$FSX_DNS@tcp:/$FSX_MOUNTNAME $FSX_MOUNTDIR lustre defaults,nofail,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=${REQUIRES_SVC} 0 0" >> /etc/fstab
    mkdir -p ${FSX_MOUNTDIR}/
    cat /etc/fstab
fi
