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
pyenv install miniforge3-latest

CONDA=~/.pyenv/versions/miniforge3-latest/bin/conda
$CONDA update --yes --update-all -n base python
$CONDA update --yes --update-all -n base

# Install jlab
$CONDA create --yes --name base-p313 python=3.13
pyenv virtualenv miniforge3-latest/envs/base-p313 jlab
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
