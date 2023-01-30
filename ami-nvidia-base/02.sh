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
cd /tmp && unzip /tmp/awscli2.zip
sudo /tmp/aws/install
export PATH=/usr/local/bin:$PATH
aws configure set default.s3.max_concurrent_requests 100
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
/usr/local/bin/aws --version
rm /tmp/awscli2.zip
rm -fr /tmp/aws/

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
wget -O /tmp/NVIDIA-Linux-driver.run "https://us.download.nvidia.com/tesla/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run"
# Headless no-32-bit install
# See: https://forums.developer.nvidia.com/t/cli-option-to-enable-disable-32bit-compatibility-drivers-in-installer/36481/2
#
# NOTE: NVIDIA-*-no-compat32.run not available for data-center card2.run not available for data-center card
# Available for e.g., http://us.download.nvidia.com/XFree86/Linux-x86_64/525.60.11/NVIDIA-Linux-x86_64-525.60.11-no-compat32.run
sudo CC=gcc10-cc sh /tmp/NVIDIA-Linux-driver.run -s --no-install-compat32-libs
echo -e 'options nvidia NVreg_EnableGpuFirmware=0' | sudo tee /etc/modprobe.d/nvidia-gsp.conf
rm /tmp/NVIDIA-Linux-driver.run

echo "Enabling nvidia-persistenced..."
cd /tmp
tar -xjf /usr/share/doc/NVIDIA_GLX-1.0/samples/nvidia-persistenced-init.tar.bz2 nvidia-persistenced-init/systemd/nvidia-persistenced.service.template
sed 's|^ExecStart=/usr/bin/nvidia-persistenced --user __USER__$|ExecStart=/usr/bin/nvidia-persistenced|' nvidia-persistenced-init/systemd/nvidia-persistenced.service.template \
    | sudo tee /usr/lib/systemd/system/nvidia-persistenced.service > /dev/null
sudo systemctl enable nvidia-persistenced.service --now
rm -fr /tmp/nvidia-persistenced-init/

echo "Installing NVIDIA Fabric Manager..."
cd /tmp
curl -O https://developer.download.nvidia.com/compute/nvidia-driver/redist/fabricmanager/linux-x86_64/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive.tar.xz
tar xf fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive.tar.xz -C /tmp
sudo rsync -al /tmp/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive/ /usr/ --exclude LICENSE
sudo mv /usr/systemd/nvidia-fabricmanager.service /usr/lib/systemd/system
sudo systemctl enable nvidia-fabricmanager --now
rm /tmp/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive.tar.xz
rm -fr /tmp/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive/

#echo "Installing NVidia docker..."
#distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
#sudo amazon-linux-extras install docker
#sudo systemctl enable docker
#curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
#sudo yum install -y nvidia-container-toolkit nvidia-docker2
#sudo sed -i 's/^OPTIONS/#&/' /etc/sysconfig/docker
#echo -e '{"default-ulimits":{"memlock":{"Name":"memlock","Soft":-1,"Hard":-1}},"default-runtime":"nvidia","runtimes":{"nvidia":{"path":"nvidia-container-runtime","runtimeArgs":[]}}}' | sudo tee /etc/docker/daemon.json
#sudo systemctl restart docker
#sudo usermod -aG docker ec2-user
#
#echo "Installing GDRCopy on the host (need the driver, see https://github.com/NVIDIA/gdrcopy/issues/197)..."
#git clone https://github.com/NVIDIA/gdrcopy.git /tmp/gdrcopy
#cd /tmp/gdrcopy/packages
#CUDA=/usr/local/cuda PATH=$PATH:/sbin ./build-rpm-packages.sh
#sudo rpm -Uvh *.rpm
