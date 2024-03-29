#!/bin/bash

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

# See: https://github.com/pyenv/pyenv#basic-github-checkout
sed -Ei -e '/^([^#]|$)/ {a \
export PYENV_ROOT="$HOME/.pyenv"
a \
export PATH="$PYENV_ROOT/bin:$PATH"
a \
' -e ':a' -e '$!{n;ba};}' ~/.profile
echo '' >> ~/.profile
echo 'eval "$(pyenv init --path)"' >> ~/.profile
cat << 'EOF' >> ~/.bashrc

if [[ ! -v PYENV_ROOT ]]; then
    export PYENV_ROOT=$HOME/.pyenv
    export PATH=$PYENV_ROOT/bin:$PATH
    eval "$(pyenv init --path)"
fi
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF

# Enable pyenv for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Miniconda3 to install pre-compiled python. Esp. on small instances like t* to
# reduce install time (and to conserve CPU credits).
#
# NOTE: Certain pyenv versions (around Oct'22 ??) install to miniforge3-x.y.z,
# so needs to manually create the miniconda3 symlink.
pyenv install miniforge3
MINIFORGE3_LATEST=$(ls -1d ~/.pyenv/versions/miniforge3-* 2> /dev/null \
    | sed -E -e '/-dev$/d' -e '/-src$/d' -e '/(b|rc)[0-9]+$/d' \
    | sort -t. -k1,1r -k 2,2nr -k 3,3nr \
)
[[ $MINIFORGE3_LATEST != "" ]] && ln -s $MINIFORGE3_LATEST $(dirname `echo $MINIFORGE3_LATEST`)/miniforge3

CONDA=~/.pyenv/versions/miniforge3/bin/conda
$CONDA update --yes --update-all -n base python
$CONDA update --yes --update-all -n base

# Install jlab
$CONDA create --yes --name base-p310 python=3.10
pyenv virtualenv miniforge3/envs/base-p310 jlab
pyenv rehash
~/.pyenv/versions/jlab/bin/pip install --upgrade pip setuptools
declare -a PKGS=(
    jupyterlab
    jupyter-server-proxy
    jupyter_bokeh
    nbdime
    jupyterlab-execute-time
    jupyterlab-skip-traceback
    jupyterlab-unfold
    stickyland

    environment_kernels

    # jupyterlab_code_formatter requires formatters in its venv.
    # See: https://github.com/ryantam626/jupyterlab_code_formatter/issues/153
    jupyterlab_code_formatter
    black
    isort
)
~/.pyenv/versions/jlab/bin/pip install --no-cache-dir "${PKGS[@]}"

# Do not show jlab's ipykernel
mv ~/.pyenv/versions/jlab/share/jupyter/kernels/python3/kernel.json{,.bak}
echo 'c.EnvironmentKernelSpecManager.blacklist_envs=["virtualenv_jlab"]' \
    >> ~/.jupyter/jupyter_notebook_config.py

$CONDA clean -a -y
