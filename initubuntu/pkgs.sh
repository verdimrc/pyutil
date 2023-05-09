#!/bin/bash

# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive
sudo apt update

# DLAMI ubuntu-20.04 has broken dependency due to linux-aws.
sudo apt --fix-broken -y install

declare -a PKG=(unzip tree fio dstat dos2unix tig jq ncdu inxi mediainfo git-lfs nvme-cli aria2)
PKG+=(ripgrep bat s4cmd python3-venv python3-pip)
[[ $(apt-cache search ^duf$) ]] && PKG+=(duf)
[[ $(command -v docker) ]] || PKG+=(docker.io)
if [[ $(uname -i) != "x86_64" ]]; then
    echo HAHA: WARNING: untested on arm
    PKG+=(
        gcc python38-devel
        the_silver_searcher  # ag, alt. to rg which has no pre-built binary for aarch64
    )
fi


################################################################################
# DLAMI ubuntu2004 is complicated.
################################################################################
# The installed kernel and nvidia-fabricmanager are already out-of-sync. Any
# attempt to update/upgrade/uhold/pin/etc, is almost guaranteed to bump to
# nvidia-fabricmanager newer than cuda-driver, this breaks torch.cuda.is_available().
#
# The workaround is to ensure the kernel required by the prebaked
# nvidia-fabricmanager is installed via fsx-client script. During the process,
# very likely to bump to nvidia-fabricmanager incompatible with installed cuda
# driver. Hence, an additional step to force downgrade nvidia-fabricmanager
# (borrow the step from PCluster).
#
# [1] https://github.com/aws/aws-parallelcluster/wiki/NVIDIA-Fabric-Manager-stops-running-on-Ubuntu-18.04-and-Ubuntu-20.04
#
# TL/DR: dlami-ubuntu-20.04 is complicated.
if [[ -e /opt/aws/dlami/bin/dlami_cloudwatch_agent.sh ]]; then
    sudo apt-mark unhold linux-aws linux-headers-aws linux-image-aws
    sudo ./install-fsx-lustre-client.sh   # Anchor to kernel with FSx Lustre client
    sudo ./fix-fabricmanager.sh           # Restore nvidia-fabricmanager [1]
fi
################################################################################


sudo apt upgrade -y
sudo apt install -y "${PKG[@]}"
sudo apt clean
[[ -e /usr/bin/batcat ]] && sudo ln -s /usr/bin/batcat /usr/bin/bat

# Install docker
sudo systemctl enable docker --now
sudo usermod -a -G docker ubuntu

# Install python-based CLI
export PATH=$HOME/.local/bin:$PATH
pip3 install --user --no-cache-dir pipx
declare -a PKG=(
    ranger-fm
    git-remote-codecommit
    pre-commit
    pipupgrade
    ruff

    cookiecutter
    jupytext
    nbdime
    #black
    #isort
    #pyupgrade
    #nbqa

    aws-sam-cli
    awslogs
    nvitop
    gpustat
)
for i in "${PKG[@]}"; do
    pipx install --pip-args="--no-cache-dir" $i
done

# https://github.com/jupyter/nbdime/issues/621
pipx inject nbdime ipython_genutils

nbdime config-git --enable --global

# Configure some of the python-based CLI
cat << 'EOF' >> ~/.bashrc

# Added by pkgs.sh
eval "$(~/.local/bin/register-python-argcomplete pipx)"
export SAM_CLI_TELEMETRY=0
EOF

mkdir -p ~/.config/ranger/
echo set line_numbers relative >> ~/.config/ranger/rc.conf

# VSCode: https://code.visualstudio.com/docs/setup/linux#_visual-studio-code-is-unable-to-watch-for-file-changes-in-this-large-workspace-error-enospc
echo -e '\nfs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
