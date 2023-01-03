#!/usr/bin/bash

CUDA_VERSION=12-0
CUDA_NVVP=cuda-nvvp-12-0
CUDA_TOOLKIT=cuda-toolkit-12-0

cd /tmp
NVIDIA_VERSION=$(modinfo nvidia | grep ^version: | awk '{print $2}')
echo Installed NVIDIA_VERSION: $NVIDIA_VERSION

echo "Installing NVIDIA Fabric Manager..."
curl -O https://developer.download.nvidia.com/compute/nvidia-driver/redist/fabricmanager/linux-x86_64/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive.tar.xz
tar xf fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive.tar.xz -C /tmp
sudo rsync -al /tmp/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive/ /usr/ --exclude LICENSE
sudo mv /usr/systemd/nvidia-fabricmanager.service /usr/lib/systemd/system
sudo systemctl enable nvidia-fabricmanager
rm /tmp/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive.tar.xz
rm -fr /tmp/fabricmanager-linux-x86_64-$NVIDIA_VERSION-archive/

# Install cuda (toolkit or profiler only)
[[ $1 == "nvvp" ]] && PKG=cuda-nvvp-$CUDA_VERSION || PKG=cuda-toolkit-$CUDA_VERSION
echo Installing "$PKG"...
sudo yum install -y $PKG
echo "Adding CUDA paths to .bashrc..."
cat << 'EOF' >> ~/.bashrc

export PATH=/usr/local/cuda/bin:$PATH
EOF
echo 'To affect current shell: export PATH=/usr/local/cuda/bin:$PATH'

# Make profiler GUI runs "by default" from terminal and GUI.
echo "
Install JDK-1.8, then patching nvvp to use this version of Java...

Without patching nvvp, you must run it from a terminal as:

    nvvp -vm /usr/lib/jvm/jre-1.8.0/bin

which is a hassle. In addition, you won't be able launch it from the Linux desktop.
"
sudo yum install -y java-1.8.0-openjdk
[[ $(grep 'jre-1.8.0' /usr/local/cuda/bin/nvvp | wc -l) == 0 ]] && sudo cp /usr/local/cuda/bin/nvvp{,.ori}
sudo sed -i 's|\(CUDA_BIN/\.\./libnvvp/nvvp \$@$\)|\1 -vm /usr/lib/jvm/jre-1.8.0/bin|' /usr/local/cuda/bin/nvvp

# Clean-up, clean-up, everybody cleans up... Clean-up, clean-up, everybody does your share.
sudo yum clean all
cat << EOF

########################################
Clear these tmp dirs manually:

sudo rm -fr $(find /tmp/dkms\.* -name 'nvidia.ko' | cut -d'/' -f1,2,3 | tr '\n' ' ')
########################################

EOF
