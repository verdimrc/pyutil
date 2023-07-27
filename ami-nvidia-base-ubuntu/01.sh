#!/usr/bin/bash

sudo bash -c "
# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

if [[ "X$1" == 'Xlustre' ]]; then
    BIN_DIR=$(dirname `readlink -e ${BASH_SOURCE[0]}`)
    \$BIN_DIR/install-fsx-lustre-client.sh
else
    apt update
fi

apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade
apt install -y dkms pkg-config git libtool autoconf cmake nasm unzip python3 python3-distutils \
    python3-wheel python3-dev python3-numpy pigz parallel nfs-common build-essential hwloc \
    libjemalloc2 libnuma-dev numactl libjemalloc-dev preload htop iftop liblapack-dev libgfortran5 \
    ipcalc wget curl devscripts debhelper check libsubunit-dev fakeroot
systemctl disable --now unattended-upgrades.service
ufw disable
apt clean

uname -r
echo 'blacklist nouveau' > tee /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'blacklist lbm-nouveau' >> /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'alias nouveau off' >> /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'alias lbm-nouveau off' >> /etc/modprobe.d/nvidia-graphics-drivers.conf

# echo "GRUB_CMDLINE_LINUX='intel_idle.max_cstate=1'" >> /etc/default/grub
"

echo "
###################################
# Will reboot the instance now... #
###################################
"

sudo reboot
