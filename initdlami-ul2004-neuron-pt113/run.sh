#!/bin/bash

set -exuo pipefail

################################################################################
# 000: Preamble
################################################################################
# Sanity checks
[[ $(lsb_release -sc) != "focal" ]] && { echo "OS is NOT Ubuntu-20.04. Exiting..." ; exit -2 ; }

PYUTIL_BRANCH=master

# Load config
BIN_DIR=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
. $BIN_DIR/config.sh

cd ~

FOR_CREATING_AMI=0
declare -a HELP=(
    "[-h|--help]"
    "[-c|--for-creating-ami]"
)
parse_args() {
    local key
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -h|--help)
            echo "Enrich AMI with pyutil goodies."
            echo "Usage: $(basename ${BASH_SOURCE[0]}) ${HELP[@]}"
            exit 0
            ;;
        -c|--for-creating-ami)
            FOR_CREATING_AMI=1
            shift
            ;;
        *)
            error_and_exit "Unknown argument: $key"
            ;;
        esac
    done
}
parse_args "$@"


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
[[ $FOR_CREATING_AMI != 0 ]] && ~/pyutil/pre-create-ami.sh


################################################################################
# 020: More Neuron packages
################################################################################
sudo apt update && sudo apt upgrade -y
( source /opt/aws_neuron_venv_pytorch/bin/activate && pip install transformers-neuronx wandb )
export PATH=~/.local/bin:$PATH
[[ $GIT_REPO != "" ]] && { git clone $GIT_REPO $GIT_LOCAL_DIR && cd $GIT_LOCAL_DIR && git checkout $GIT_CHECKOUT_TO ; }


################################################################################
# 030: Setup shared filesystems
################################################################################
sudo \
    EFS_DNS=$EFS_DNS \
    EFS_MOUNTDIR=$EFS_MOUNTDIR \
    ~/initubuntu/install-efs.sh

sudo \
    FSX_DNS=$FSX_DNS \
    FSX_MOUNTNAME=$FSX_MOUNTNAME \
    FSX_MOUNTDIR=$FSX_MOUNTDIR \
    ~/initubuntu/install-fsx-lustre-client.sh


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
"
