#!/bin/bash

sudo amazon-linux-extras install -y docker python3.8 epel
sudo yum install -y tree htop fio dstat dos2unix git tig jq
sudo yum clean all

# Install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install python-based CLI
pip3.8 install --user --no-cache-dir pipx
declare -a PKG=(
    git-remote-codecommit
    pre-commit
    ranger-fm
    cookiecutter
    black
    black-nb
    isort
    pyupgrade
    nbdime
    nbqa
    jupytext
    s4cmd
    aws-sam-cli
)
for i in "${PKG[@]}"; do
    pipx install $i
done

# Configure some of the python-based CLi
cat << 'EOF' >> ~/.bashrc

# Added by pkgs.sh
eval "$(~/.local/bin/register-python-argcomplete pipx)"
export SAM_CLI_TELEMETRY=0
EOF

mkdir -p ~/.config/ranger/
echo set line_numbers relative >> ~/.config/ranger/rc.conf
