#!/usr/bin/bash

echo "NOT YET PORTED TO UBUNTU!"
exit -1

CUDA_VERSION=12-0
CUDA_NVVP=cuda-nvvp-12-0
CUDA_TOOLKIT=cuda-toolkit-12-0

cd /tmp
NVIDIA_VERSION=$(modinfo nvidia | grep ^version: | awk '{print $2}')
echo Installed NVIDIA_VERSION: $NVIDIA_VERSION

# Install cuda (toolkit or profiler only)
# sudo yum -y install {{user `cuda_version`}} {{user `cudnn_version`}} {{user `cudnn_version`}}-devel
[[ $1 == "nvvp" ]] && PKG=cuda-nvvp-$CUDA_VERSION || PKG=cuda-toolkit-$CUDA_VERSION
echo Installing "$PKG"...
sudo yum install -y $PKG
echo "Adding CUDA paths to system-wide profile's PATH..."
echo -e '#!/bin/sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
export PATH=$PATH:/usr/local/cuda/bin' | sudo tee /etc/profile.d/cuda.sh
sudo chmod +x /etc/rc.local
echo 'To affect current shell: export PATH=/usr/local/cuda/bin:$PATH'

# Make profiler GUI runs "by default" from terminal and GUI.
echo "
Patch nvpp to use JDK-1.8, otherwise it's a hassle to run from a terminal as follows, and fails to launch from Linux desktop:

    nvvp -vm /usr/lib/jvm/jre-1.8.0/bin
"
sudo yum install -y java-1.8.0-openjdk
[[ $(grep 'jre-1.8.0' /usr/local/cuda/bin/nvvp | wc -l) == 0 ]] && sudo cp /usr/local/cuda/bin/nvvp{,.ori}
sudo sed -i 's|\(CUDA_BIN/\.\./libnvvp/nvvp \$@$\)|\1 -vm /usr/lib/jvm/jre-1.8.0/bin|' /usr/local/cuda/bin/nvvp

# Clean-up
sudo yum clean all
