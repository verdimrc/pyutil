#!/bin/bash

# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

sudo add-apt-repository ppa:git-core/ppa -y

# Repo to newer git-lfs to avoid https://github.com/git-lfs/git-lfs/issues/5310#issuecomment-1647829918
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

sudo apt update

declare -a PKG=(unzip tree fio dstat dos2unix tig jq inxi mediainfo git-lfs nvme-cli aria2)
PKG+=(python3-venv python3-pip)
[[ $(command -v docker) ]] || PKG+=(docker.io)
if [[ $(uname -i) != "x86_64" ]]; then
    echo HAHA: WARNING: untested on arm
    PKG+=(
        gcc python3-dev
        the_silver_searcher  # ag, alt. to rg which has no pre-built binary for aarch64
    )
fi

echo 'export DSTAT_OPTS="-cdngym"' >> ~/.bashrc

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
