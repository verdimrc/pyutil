#!/usr/bin/bash

sudo bash -c "
# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

if [[ "X$1" == 'Xlustre' ]]; then
    wget -O - https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc \
        | gpg --dearmor \
        > /usr/share/keyrings/fsx-ubuntu-public-key.gpg

    echo 'deb [signed-by=/usr/share/keyrings/fsx-ubuntu-public-key.gpg] https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu $(lsb_release -cs) main' \
        > /etc/apt/sources.list.d/fsxlustreclientrepo.list
fi

apt update

if [[ "X$1" == 'lustre' ]]; then
    # Remove meta-package linux-aws whose version is frequently ahead of lustre-client-modules-aws
    apt remove -y linux-aws linux-headers-aws linux-image-aws
    apt install -y lustre-client-modules-aws
fi

apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade
apt install -y dkms pkg-config git libtool autoconf cmake nasm unzip python3 python3-distutils \
    python3-wheel python3-dev python3-numpy pigz parallel nfs-common build-essential hwloc \
    libjemalloc2 libnuma-dev numactl libjemalloc-dev preload htop iftop liblapack-dev libgfortran5 \
    ipcalc wget curl devscripts debhelper check libsubunit-dev fakeroot
systemctl disable unattended-upgrades.service
ufw disable
apt clean

uname -r
echo 'blacklist nouveau' > tee /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'blacklist lbm-nouveau' >> /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'alias nouveau off' >> /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'alias lbm-nouveau off' >> /etc/modprobe.d/nvidia-graphics-drivers.conf

# echo "GRUB_CMDLINE_LINUX='intel_idle.max_cstate=1'" >> /etc/default/grub
"

cat << 'EOF'

###################################
# Will reboot the instance now... #
###################################

EOF

sudo reboot
