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

systemctl disable --now unattended-upgrades.service

BIN_DIR=$(get_bin_dir)
${BIN_DIR}/pkgs.sh
${BIN_DIR}/awscliv2.sh
[[ $(command -v duf) ]] || ${BIN_DIR}/duf.sh
${BIN_DIR}/s5cmd.sh
${BIN_DIR}/delta.sh
${BIN_DIR}/adjust-git.sh 'Firstname Lastname' first.last@email.abc
${BIN_DIR}/term.sh
sudo ${BIN_DIR}/install-gpu-cwagent.sh
${BIN_DIR}/patch-bash-config.sh
${BIN_DIR}/fix-aws-config.sh
${BIN_DIR}/fix-osx-keymap.sh
${BIN_DIR}/install-cdk.sh
${BIN_DIR}/fix-ipython.sh
${BIN_DIR}/install-py-ds.sh
${BIN_DIR}/customize-jlab.sh
${BIN_DIR}/vim.sh
${BIN_DIR}/tmux.sh
sudo ${BIN_DIR}/prep-instance-store-svc.sh

# These require jupyter lab restarted and browser reloaded, to see the changes.
${BIN_DIR}/patch-jupyter-config.sh
