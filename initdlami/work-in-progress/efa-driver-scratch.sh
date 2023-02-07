echo "Updating sysctl..."
echo 'kernel.yama.ptrace_scope = 0' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

EFA_PKG=aws-efa-installer-1.21.tar.gz
EFA_PKG=aws-efa-installer-latest.tar.gz

cd /tmp
wget -O /tmp/aws-efa-installer.tar.gz https://efa-installer.amazonaws.com/$EFA_PKG
tar -xf /tmp/aws-efa-installer.tar.gz -C /tmp
cd /tmp/aws-efa-installer

# Host. On alinux2, memlock already -1, nofile already 64k (> 8k in efa-config).
sudo ./efa_installer.sh -y --debug-packages --minimal
#
#skipping efa-profile-1.5-1.amzn2.noarch because of minimal installation
#skipping libfabric-aws-1.16.1amzn3.0-1.amzn2.x86_64 because of minimal installation
#skipping libfabric-aws-devel-1.16.1amzn3.0-1.amzn2.x86_64 because of minimal installation
#skipping openmpi40-aws-4.1.4-3.x86_64 because of minimal installation
# ...
# skipping libfabric-aws-debuginfo-1.16.1amzn3.0-1.amzn2.x86_64 because of minimal installation
#
# Remove /etc/security/limits.d/01_efa.conf, because default alinux2 is already 64k
sudo sed -i 's/^\*/#*/g' /etc/security/limits.d/01_efa.conf

# Container:
# We already changed memlock ulimit in /etc/docker/daemon.json.
# Also, container may already default to higher nofile.
./efa_installer.sh -y --debug --skip-kmod --skip-limit-conf

# If testing installation withion container, then current shells' path
source /etc/profile.d/amazon_efa.sh


# Host. On alinux2, memlock already -1, nofile already 8k (= efa-config).
sudo ./efa_installer.sh -y --debug-packages
# Remove nofile 8192 from /etc/security/limits.d/01_efa.conf, because default alinux2 is already 64k


# NOTE: --ulimit memlock=1 already in /etc/docker/daemon.json
docker run --rm -it --shm-size=1g --ulimit stack=67108864 --gpus=all --device /dev/infiniband/uverbs0 --device /dev/infiniband/uverbs1 --device /dev/infiniband/uverbs2 --device /dev/infiniband/uverbs3 <image:tag>

fi_info -p efa -t FI_EP_RDM

# Reboot


EFA install minimal:
Resolving Dependencies
--> Running transaction check
---> Package ibacm.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package infiniband-diags.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package libibumad.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package libibverbs.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package libibverbs-core.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package libibverbs-utils.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package librdmacm.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package librdmacm-utils.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package rdma-core.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package rdma-core-debuginfo.x86_64 0:43.0-1.amzn2.0.2 will be installed
---> Package rdma-core-devel.x86_64 0:43.0-1.amzn2.0.2 will be installed


###

# NOTE: remove -v /dev/gdrdrv:/dev/gdrdrv when on the correct instance.
# NOTE: below is for g4dn.8xlarge with 1x EFA.
# NOTE: EFA requires --privileged
docker run -it --rm --gpus all --device /dev/gdrdrv --device /dev/infiniband/uverbs0 haha:latest /bin/bash

docker run --rm -it --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 --gpus=all --device /dev/infiniband/uverbs0 <image:tag>