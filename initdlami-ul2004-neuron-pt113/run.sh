#!/bin/bash

set -exuo pipefail

################################################################################
# 000: Preamble
################################################################################
# Sanity checks
[[ $(lsb_release -sc) != "focal" ]] && { echo "OS is NOT Ubuntu-20.04. Exiting..." ; exit -2 ; }

#PYUTIL_BRANCH=main
PYUTIL_BRANCH=dlami-ul2004-neuron

# Load config
BIN_DIR=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
. $BIN_DIR/config.sh

cd ~


################################################################################
# 010: Begin by applying my standard init scripts
################################################################################
[[ -d ~/pyutil ]] && rm -fr ~/pyutil/
git clone https://github.com/verdimrc/pyutil
(cd pyutil && git checkout $PYUTIL_BRANCH)
~/pyutil/initubuntu/install-initami.sh -l --no-py-ds --git-user "$GIT_USER" --git-email "$GIT_EMAIL"

# Remove general-purpose bloat...
sed -i \
    -e 's|^\(sudo .*/install-gpu-cwagent.sh\)$|#\1|' \
    -e 's|^\(.*/install-cdk.sh\)$|#\1|' \
    ~/initubuntu/setup-my-ami.sh
sed -i \
    -e 's/aws-sam-cli/#aws-sam-cli/' \
    -e 's/nvitop/#nvitop/' \
    -e 's/gpustat/#gpustat/' \
    ~/initubuntu/pkgs.sh

~/initubuntu/setup-my-ami.sh


################################################################################
# 020: More Neuron packages
################################################################################
sudo apt update && sudo apt upgrade -y
( source /opt/aws_neuron_venv_pytorch/bin/activate && pip install transformers-neuronx )
[[ $GIT_REPO != "" ]] && { git clone $GIT_REPO && git checkout $GIT_CHECKOUT_TO ; }


################################################################################
# 030: Setup EFS
################################################################################
# Install efs mounter
git clone https://github.com/aws/efs-utils
pushd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
popd

# Extra yard: patch /etc/fstab with EFS.
sudo mkdir -p $EFS_MOUNTDIR

# Add template entry for usability
[[ $(grep "^# EFS_DNS_NAME@tcp:" /etc/fstab 2> /dev/null) ]] \
    || echo \
        "# EFS_DNS_NAME@tcp:/ <LOCAL_MOUNT_DIR> efs _netdev,noresvport,tls 0 0" \
        | sudo tee -a /etc/fstab

if [[ ! $EFS_DNS =~ "efs_file_system_dns_name" ]]; then
    # Comment out any old entry.
    sudo sed -i "s|^\([^#].* $EFS_MOUNTDIR efs .*$\)|#\1|g" /etc/fstab

    # Add entry for the specific volume
    echo "$EFS_DNS@tcp:/ $EFS_MOUNTDIR efs_netdev,noresvport,tls 0 0" | sudo tee -a /etc/fstab
    sudo mkdir -p ${EFS_MOUNTDIR}/
    cat /etc/fstab
fi


################################################################################
# 040: Setup FSx Lustre
################################################################################
sudo \
    FSX_DNS=$FSX_DNS \
    FSX_MOUNTNAME=$FSX_MOUNTNAME \
    FSX_MOUNTDIR=$FSX_MOUNTDIR \
    ~/initubuntu/install-fsx-lsutre-client.sh


################################################################################
# 050: Setup FSx Lustre
################################################################################
echo "
########################################
# Finished enriching DLAMI for Neuron. #
#                                      #
# Your next step:                      #
#                                      #
#     sudo reboot                      #
########################################
