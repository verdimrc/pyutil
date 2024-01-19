#!/bin/bash

# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update

declare -a PKG=(unzip tree fio dstat dos2unix tig jq ncdu inxi mediainfo git-lfs nvme-cli aria2)
PKG+=(ripgrep bat python3-venv python3-pip)
[[ $(apt-cache search ^duf$) ]] && PKG+=(duf)
[[ $(command -v docker) ]] || PKG+=(docker.io)

echo 'export DSTAT_OPTS="-cdngym"' >> ~/.bashrc

sudo apt upgrade -y
sudo apt install -y "${PKG[@]}"
sudo apt clean
[[ -e /usr/bin/batcat ]] && sudo ln -s /usr/bin/batcat /usr/bin/bat

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
    #isort #pyupgrade
    #nbqa

    #aws-sam-cli
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
