#!/usr/bin/bash

sudo amazon-linux-extras install -y lustre2.10 epel kernel-5.10
sudo yum -y update
sudo yum install -y amazon-cloudwatch-agent python3 yum-utils ldconfig cmake dkms mdadm git htop hwloc iftop kernel-tools rpm-build rpmdevtools numactl parallel pigz python3-distutils wget kernel-devel kernel-headers make check check-devel subunit subunit-devel
sudo yum groupinstall -y 'Development Tools'
uname -r
echo 'blacklist nouveau' | sudo tee /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'blacklist lbm-nouveau' | sudo tee -a /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'alias nouveau off' | sudo tee -a /etc/modprobe.d/nvidia-graphics-drivers.conf
echo 'alias lbm-nouveau off' | sudo tee -a /etc/modprobe.d/nvidia-graphics-drivers.conf

cat << 'EOF'

###################################
# Will reboot the instance now... #
###################################

EOF

sudo reboot
#sudo shutdown -r now
