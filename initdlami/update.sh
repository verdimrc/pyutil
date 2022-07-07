#!/bin/bash

sudo yum update -y

CONDA=~/.pyenv/versions/miniforge3/bin/conda
$CONDA update --yes --update-all -n base
$CONDA update --yes --update-all -n base-p310
$CONDA clean -a -y

~/.local/bin/pipx upgrade-all
~/.local/pipx/venvs/pipupgrade/bin/python3 -m pip install --upgrade \
    --no-cache-dir 'git+https://github.com/achillesrasquinha/bpyutils.git@develop#egg=bpyutils'

# TODO: nvm, cdk
echo TODO: nvm, cdk

~/initdlami/bat.sh   # TODO: remove old version
~/initdlami/delta.sh # TODO: remove old version
~/initdlami/s5cmd.sh # TODO: remove old version

EPILOGUE=$(cat << 'EOF'

#######################################
Upgrade pyenv-virtualenv by as follows:
#######################################

pyenv activate my-env
pipupgrade --pip-path $VIRTUAL_ENV/bin/pip3 --latest
EOF
)
echo -e "${EPILOGUE}\n"
