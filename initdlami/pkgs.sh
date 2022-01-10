#!/bin/bash

sudo amazon-linux-extras install -y docker python3.8 epel
sudo yum update -y
sudo yum install -y tree htop fio dstat dos2unix git tig jq
sudo yum clean all

# Install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install python-based CLI
pip3.8 install --user --no-cache-dir pipx
declare -a PKG=(
    ranger-fm
    git-remote-codecommit
    pre-commit

    cookiecutter
    black
    black-nb
    isort
    pipupgrade
    pyupgrade

    nbdime
    nbqa
    jupytext

    s4cmd
    aws-sam-cli
    awslogs
)
for i in "${PKG[@]}"; do
    pipx install --pip-args="--no-cache-dir" $i
done

# Hack: pipx didn't install pipupgrade dependency
~/.local/pipx/venvs/pipupgrade/bin/python3 -m pip install \
    --no-cache-dir \
    'git+https://github.com/achillesrasquinha/bpyutils.git@develop#egg=bpyutils'

# Configure some of the python-based CLi
cat << 'EOF' >> ~/.bashrc

# Added by pkgs.sh
eval "$(~/.local/bin/register-python-argcomplete pipx)"
export SAM_CLI_TELEMETRY=0
EOF

mkdir -p ~/.config/ranger/
echo set line_numbers relative >> ~/.config/ranger/rc.conf
