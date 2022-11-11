#!/bin/bash

sudo amazon-linux-extras install -y docker python3.8 epel
sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/cyqsimon/el-rust-pkgs/repo/epel-7/cyqsimon-el-rust-pkgs-epel-7.repo
sudo yum update -y
sudo yum install -y tree htop fio dstat dos2unix git tig jq ncdu ripgrep bat git-delta
sudo yum clean all

# Install docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Install python-based CLI
pip3.8 install --user --no-cache-dir pipx
declare -a PKG=(
    ranger-fm
    git-remote-codecommit
    pre-commit
    pipupgrade

    cookiecutter
    jupytext
    nbdime
    #black
    #isort
    #pyupgrade
    #nbqa

    s4cmd
    aws-sam-cli
    awslogs
    nvitop
    gpustat
)
for i in "${PKG[@]}"; do
    pipx install --pip-args="--no-cache-dir" $i
done

# Hack: pipx didn't install pipupgrade dependency
~/.local/pipx/venvs/pipupgrade/bin/python3 -m pip install \
    --no-cache-dir \
    'git+https://github.com/achillesrasquinha/bpyutils.git@develop#egg=bpyutils'

nbdime config-git --enable --global

# Configure some of the python-based CLI
cat << 'EOF' >> ~/.bashrc

# Added by pkgs.sh
eval "$(~/.local/bin/register-python-argcomplete pipx)"
export SAM_CLI_TELEMETRY=0
EOF

mkdir -p ~/.config/ranger/
echo set line_numbers relative >> ~/.config/ranger/rc.conf
