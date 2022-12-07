#!/usr/bin/bash

cd /tmp

# Search driver version on https://www.nvidia.com/Download/Find.aspx
NVIDIA_VERSION=515.86.01  # [20221222] Support up to CUDA 11.7
NVIDIA_VERSION=525.60.13  # [20221205] Support up to CUDA 12.0

echo "Assert nouveau modules are blacklisted..."
assert_blacklisted() {
    local module_name="$1"
    sudo modprobe $module_name &> /dev/null
    if [[ $? == 0 ]]; then
        echo "Module $module_name has not been blacklisted"
        #exit 1
    fi
}
assert_blacklisted nouveau
assert_blacklisted lbm-nouveau

echo "Updating sysctl..."
echo 'net.core.default_qdisc = fq' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_timestamps = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max = 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 67108864' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Installing awscli-v2..."
wget -O /tmp/awscli2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
cd /tmp && sudo unzip /tmp/awscli2.zip
sudo /tmp/aws/install
export PATH=/usr/local/bin:$PATH
aws configure set default.s3.max_concurrent_requests 100
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
/usr/local/bin/aws --version
rm /tmp/awscli.zip

echo "Configuring ssh client tailored for cluster computing..."
echo '    StrictHostKeyChecking no' | sudo tee -a /etc/ssh/ssh_config
echo '    HostbasedAuthentication no' | sudo tee -a /etc/ssh/ssh_config
echo '    CheckHostIP no' | sudo tee -a /etc/ssh/ssh_config

echo "Installing NVIDIA driver..."
cd /tmp
#sudo yum install -y gcc10 kernel-devel kernel-headers # Already done in 01.sh
#
# This doesn't seem needed by driver installation
sudo yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
sudo yum clean all
sudo sed -i '/^\[main\]/a\exclude=kernel*' /etc/yum.conf
#
wget -O /tmp/NVIDIA-Linux-driver.run "https://us.download.nvidia.com/tesla/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run"
#sudo CC=gcc10-cc sh /tmp/NVIDIA-Linux-driver.run -q -a --ui=none
# -a is to automatically accept license, only needed for old installer (how old?)
# -q, --no-questions: assumed default for all questions.
# -s, --silent implies '--ui=none --no-questions'
#
# Headless no-32-bit install
# See: https://forums.developer.nvidia.com/t/cli-option-to-enable-disable-32bit-compatibility-drivers-in-installer/36481/2
#
# NOTE: NVIDIA-*-no-compat32.run not available for data-center card2.run not available for data-center card
# Available for e.g., http://us.download.nvidia.com/XFree86/Linux-x86_64/525.60.11/NVIDIA-Linux-x86_64-525.60.11-no-compat32.run
sudo CC=gcc10-cc sh /tmp/NVIDIA-Linux-driver.run -s --no-install-compat32-libs
#
## Install CUDA_toolkit
# sudo curl -O https://developer.download.nvidia.com/compute/nvidia-driver/redist/fabricmanager/linux-x86_64/fabricmanager-linux-x86_64-{{user `nvidia_version`}}-archive.tar.xz
# sudo tar xf fabricmanager-linux-x86_64-{{user `nvidia_version`}}-archive.tar.xz -C /tmp
# sudo rsync -al /tmp/fabricmanager-linux-x86_64-{{user `nvidia_version`}}-archive/ /usr/ --exclude LICENSE
# sudo mv /usr/systemd/nvidia-fabricmanager.service /usr/lib/systemd/system
# sudo systemctl enable nvidia-fabricmanager
# sudo yum -y install {{user `cuda_version`}} {{user `cudnn_version`}} {{user `cudnn_version`}}-devel
# echo -e 'options nvidia NVreg_EnableGpuFirmware=0' | sudo tee /etc/modprobe.d/nvidia-gsp.conf
# echo -e '#!/bin/sh
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
# export PATH=$PATH:/usr/local/cuda/bin' | sudo tee /etc/profile.d/cuda.sh
# sudo chmod +x /etc/rc.local

## Manual clean-up. Does reboot auto-clean these?
rm /tmp/NVIDIA-Linux-driver.run
