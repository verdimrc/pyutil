#!/bin/bash

sudo amazon-linux-extras install -y docker python3.8 epel
sudo yum update -y
sudo yum install -y tree htop fio dstat dos2unix git tig jq golang ncdu
sudo yum clean all

# Install docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Install s5cmd
latest_s5cmd_release() {
  curl --silent "https://api.github.com/repos/peak/s5cmd/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}
go env -w GO111MODULE=on
go get github.com/peak/s5cmd@$(latest_s5cmd_release)
cat << 'EOF' >> ~/.bashrc

export PATH=~/go/bin:$PATH
EOF

# Install python-based CLI
pip3.8 install --user --no-cache-dir pipx
declare -a PKG=(
    ranger-fm
    git-remote-codecommit
    pre-commit

    cookiecutter
    black
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

nbdime config-git --enable --global

# Configure some of the python-based CLI
cat << 'EOF' >> ~/.bashrc

# Added by pkgs.sh
eval "$(~/.local/bin/register-python-argcomplete pipx)"
export SAM_CLI_TELEMETRY=0
EOF

mkdir -p ~/.config/ranger/
echo set line_numbers relative >> ~/.config/ranger/rc.conf
