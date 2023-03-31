#!/usr/bin/bash

cd /tmp

# Search driver version on:
# - https://www.nvidia.com/Download/Find.aspx
# - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ (replace 2204 as needed)
NVIDIA_VERSION=525.105.17  # [20230330] Support up to CUDA 12.0

NVIDIA_MAJOR_VER=${NVIDIA_VERSION%%.*}

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
echo 'kernel.yama.ptrace_scope = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_timestamps = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max = 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 30000' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_default = 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_default = 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_mem = 67108864 67108864 67108864' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.route.flush = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Installing awscli-v2..."
wget -O /tmp/awscli2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
cd /tmp && unzip -q /tmp/awscli2.zip
sudo /tmp/aws/install --update
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
sudo bash -c "
UBUNTU_SHORT_VERSION=$(lsb_release -rs | tr -d '.')
wget -O /tmp/cuda.pin https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_SHORT_VERSION}/x86_64/cuda-ubuntu${UBUNTU_SHORT_VERSION}.pin
mv /tmp/cuda.pin /etc/apt/preferences.d/cuda-repository-pin-600

wget -O - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_SHORT_VERSION}/x86_64/3bf863cc.pub \
    | gpg --dearmor \
    > /usr/share/keyrings/nvidia-public-key.gpg >/dev/null

echo 'deb [signed-by=/usr/share/keyrings/nvidia-public-key.gpg] http://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_SHORT_VERSION}/x86_64/ /
# deb-src [signed-by=/usr/share/keyrings/nvidia-public-key.gpg] http://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_SHORT_VERSION}/x86_64/ /' \
    > /etc/apt/sources.list.d/nvidia.list

export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# Didn't find Singapore mirror, so try our luck to speed-up the download of nvidia drivers.
add-apt-repository -y ppa:apt-fast/stable

apt update
apt install apt-fast
apt-fast install -y -o Dpkg::Options::='--force-overwrite' cuda-drivers-fabricmanager-${NVIDIA_MAJOR_VER}=$NVIDIA_VERSION-1 datacenter-gpu-manager
systemctl enable nvidia-fabricmanager.service
apt-mark hold nvidia*

echo -e '#!/bin/sh\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64\nexport PATH=$PATH:/usr/local/cuda/bin' > /etc/profile.d/cuda.sh
chmod +x /etc/profile.d/cuda.sh
sed -i '/Unattended/s/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades
"

echo "Installing NVidia docker..."
cd /tmp
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get install -y docker.io nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo python3 -c '
import json
with open("/etc/docker/daemon.json") as f:
    d = json.load(f)
d["default-runtime"] = "nvidia"
d["default-ulimits"] = d.get("default-limits", {"memlock": {"Name": "memlock", "Soft": -1, "Hard": -1}})
print(json.dumps(d, indent=2))
with open("/etc/docker/daemon.json", "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
'
sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker ubuntu

echo "Adventurous: install GDRCopy driver only on the host..."
# - https://github.com/NVIDIA/gdrcopy/issues/236
# - https://github.com/NVIDIA/gdrcopy/issues/197
# - https://github.com/NVIDIA/gdrcopy/issues/138
git clone https://github.com/NVIDIA/gdrcopy.git /tmp/gdrcopy
patch /tmp/gdrcopy/packages/build-deb-packages.sh build-gdrdrv.patch -o /tmp/gdrcopy/packages/build-deb-packages-drv.sh
cd /tmp/gdrcopy/packages
# In case the library & dev must the driver version.
GDRCOPY_COMMIT=$(git rev-parse HEAD)
echo "$GDRCOPY_COMMIT
$(git show $GDRCOPY_COMMIT)" > ~/GDRCOPY-commit-sha.txt
chmod 755 build-deb-packages-drv.sh
./build-deb-packages-drv.sh
sudo apt install -y ./gdrdrv-dkms_*.Ubuntu*.deb
[[ -e /dev/gdrdrv ]] && echo "gdrcopy driver installed & loaded..." || echo "ERROR: gdrcopy driver..."
cd /tmp/
rm -fr /tmp/gdrcopy/ /tmp/gdr.*

echo "Generate HOWTO-TUNE-DOCKER.md..."
cat << 'EOF' > ~/HOWTO-TUNE-DOCKER.md
# Tips to tune Docker containers <!-- omit in toc -->

```bash
docker run -it --rm --gpus all -v /dev/gdrdrv:/dev/gdrdrv ubuntu:22.04 /bin/bash
# Container will have nvidia-smi, /dev/nvidia*, and /dev/gdrcopy.

# TODO: once EFA driver installed, also add -v /dev/uverb...:/dev/uverb...
```
EOF

echo "Clean-up..."
sudo apt clean
