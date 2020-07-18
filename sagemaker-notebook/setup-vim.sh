#!/bin/bash

# IMPORTANT: this script assumes .vimrc uses junegunn/vim-plug.
#
# If you use another .vimrc with a different plugin manager, please update this
# script accordingly to match the new plugin manager.
VIMRC_SRC=${1:-https://raw.githubusercontent.com/verdimrc/linuxcfg/master/.vimrc}

VIM_SM_ROOT=/home/ec2-user/SageMaker
VIM_RTP=${VIM_SM_ROOT}/.vim

symlink_vimrc() {
    rm /home/ec2-user/.vimrc
    ln -s ${VIM_SM_ROOT}/.vimrc /home/ec2-user/.vimrc
    echo "Created vim symlinks"
}

################################################
# Existing notebook: reuse past initialization #
################################################
if [[ -f ${VIM_RTP}/_SUCCESS ]]; then
    symlink_vimrc
    exit 0
fi


########################
# Initialization steps #
########################
echo "Initializing vim from ${VIMRC_SRC}"

curl -L $VIMRC_SRC >> ${VIM_SM_ROOT}/.vimrc
sed -i "s|^call plug#begin.*$|call plug#begin('$VIM_RTP/plugged')|g" ${VIM_SM_ROOT}/.vimrc
symlink_vimrc
curl -fLo ${VIM_RTP}/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -E +PlugInstall +qall > /dev/null
touch ${VIM_RTP}/_SUCCESS

echo "Vim initialized"
