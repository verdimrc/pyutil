#!/bin/bash

# https://gist.github.com/verdimrc/a10dd3ea00a34b0ffb3e8ee8d5cde8b5#file-bash-sh-L20-L34
#
# Utility function to get script's directory (deal with Mac OSX quirkiness).
# This function is ambidextrous as it works on both Linux and OSX.
get_bin_dir() {
    local READLINK=readlink
    if [[ $(uname) == 'Darwin' ]]; then
        READLINK=greadlink
        if [ $(which greadlink) == '' ]; then
            echo '[ERROR] Mac OSX requires greadlink. Install with "brew install greadlink"' >&2
            exit 1
        fi
    fi

    local BIN_DIR=$(dirname "$($READLINK -f ${BASH_SOURCE[0]})")
    echo -n ${BIN_DIR}
}

# https://askubuntu.com/a/1431746
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

sudo systemctl disable --now unattended-upgrades.service

## Generic stuffs
BIN_DIR=$(get_bin_dir)
${BIN_DIR}/pkgs.sh
${BIN_DIR}/term.sh
${BIN_DIR}/patch-bash-config.sh
[[ $(uname) == 'Darwin' ]] && ${BIN_DIR}/fix-osx-keymap.sh
${BIN_DIR}/vim.sh
${BIN_DIR}/tmux.sh
for i in ${BIN_DIR}/cli/*.sh; do echo $i; $i ; done
${BIN_DIR}/adjust-git.sh 'Firstname Lastname' first.last@email.abc  # Depends on install-cli/delta.sh

## Python stuffs
${BIN_DIR}/py/fix-ipython.sh
# ${BIN_DIR}/py/install-py-ds.sh
${BIN_DIR}/py/customize-jlab.sh
${BIN_DIR}/py/patch-jupyter-config.sh  # Must restart (jupyter lab + reload browser) to see changes.

## Cloud stuffs
# ${BIN_DIR}/aws/awscliv2.sh
# ${BIN_DIR}/aws/s5cmd.sh
# sudo ${BIN_DIR}/aws/install-gpu-cwagent.sh
# ${BIN_DIR}/aws/fix-aws-config.sh
# ${BIN_DIR}/aws/install-cdk.sh
# sudo ${BIN_DIR}/aws/prep-instance-store-svc.sh

sudo systemctl enable --now unattended-upgrades.service
