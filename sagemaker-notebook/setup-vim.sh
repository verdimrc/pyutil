#!/bin/bash

# IMPORTANT: this script assumes .vimrc uses junegunn/vim-plug.
#
# If you use another .vimrc with a different plugin manager, please update this
# script accordingly to match the new plugin manager.
VIMRC_SRC=${1:-https://raw.githubusercontent.com/verdimrc/linuxcfg/master/.vimrc}

VIM_SM_ROOT=/home/ec2-user/SageMaker
VIM_RTP=${VIM_SM_ROOT}/.vim


###############################################################################
# On a restarted notebook, just create symlinks to existing configurations
###############################################################################
if [[ -f ${VIM_RTP}/_SUCCESS ]]; then
    rm /home/ec2-user/.vimrc
    ln -s ${VIM_SM_ROOT}/.vimrc /home/ec2-user/.vimrc
    echo "Created vim symlinks"
    exit 0
fi


###############################################################################
# On a fresh notebook, create configurations + plugins under ~/SageMaker/
###############################################################################

echo "Downloading .vimrc from ${VIMRC_SRC}"
curl -L $VIMRC_SRC >> /home/ec2-user/.vimrc

echo "Installing vim-plug..."
curl -fLo ${VIM_RTP}/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cat << EOF > /home/ec2-user/.vimrc
" Relocate /home/ec2-user/.vim to ${VIM_RTP}
set rtp+=${VIM_RTP}

EOF

echo "Installing vim plugins..."
vim -E +PlugInstall +qall > /dev/null
touch ${VIM_RTP}/_SUCCESS

echo "Successfully initialized vim config & plugins"
