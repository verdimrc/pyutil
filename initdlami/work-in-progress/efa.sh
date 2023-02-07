#!/bin/bash

# Change DRIVER_ONLY to 1 to install just the driver, without userspace at all.
: "${DRIVER_ONLY:=0}"

[[ ! $(lspci -n | grep efa | wc -l) -gt 0 ]] \
    && echo "WARNING: does not detect EFA devices on this instance..."

# Minimal will skip packages:
#
# skipping efa-profile-1.5-1.amzn2.noarch because of minimal installation
# skipping libfabric-aws-1.16.1amzn3.0-1.amzn2.x86_64 because of minimal installation
# skipping libfabric-aws-devel-1.16.1amzn3.0-1.amzn2.x86_64 because of minimal installation
# skipping openmpi40-aws-4.1.4-3.x86_64 because of minimal installation
# skipping libfabric-aws-debuginfo-1.16.1amzn3.0-1.amzn2.x86_64 because of minimal installation
[[ $DRIVER_ONLY == 1 ]] && ARGS="--minimal" || ARGS="--debug-packages"

echo "Updating sysctl..."
echo 'kernel.yama.ptrace_scope = 0' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

EFA_PKG=aws-efa-installer-latest.tar.gz

cd /tmp
wget -O /tmp/aws-efa-installer.tar.gz https://efa-installer.amazonaws.com/$EFA_PKG
tar -xf /tmp/aws-efa-installer.tar.gz -C /tmp
cd /tmp/aws-efa-installer


sudo ./efa_installer.sh -y $ARGS

# Remove /etc/security/limits.d/01_efa.conf, because on alinux2, memlock is
# already -1, and nofile is already 64k (> 8k in efa-config).
sudo sed -i 's/^\*/#*/g' /etc/security/limits.d/01_efa.conf
cat /etc/security/limits.d/01_efa.conf
