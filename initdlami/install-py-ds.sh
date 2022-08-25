#!/bin/bash

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

# See: https://github.com/pyenv/pyenv#basic-github-checkout
sed -Ei -e '/^([^#]|$)/ {a \
export PYENV_ROOT="$HOME/.pyenv"
a \
export PATH="$PYENV_ROOT/bin:$PATH"
a \
' -e ':a' -e '$!{n;ba};}' ~/.bash_profile
echo '' >> ~/.bash_profile
echo 'eval "$(pyenv init --path)"' >> ~/.bash_profile
#echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
#echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
#echo 'eval "$(pyenv init --path)"' >> ~/.profile
echo '' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Enable pyenv for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
pyenv rehash

# Miniconda3 to install pre-compiled python. Esp. on small instances like t* to
# reduce install time (and to conserve CPU credits).
pyenv install miniforge3
CONDA=~/.pyenv/versions/miniforge3/bin/conda
$CONDA update --yes --update-all -n base python
$CONDA update --yes --update-all -n base

# Install jlab
$CONDA create --yes --name base-p310 python=3.10
pyenv virtualenv miniforge3/envs/base-p310 jlab
~/.pyenv/versions/jlab/bin/pip install --upgrade pip setuptools
declare -a PKGS=(
    jupyterlab
    jupyter-server-proxy
    jupyter_bokeh
    nbdime
    jupyterlab-execute-time
    jupyterlab-skip-traceback

    # This forked version enables debugger for kernels with ipykernel>=6.*
    'git+https://github.com/verdimrc/jupyter_environment_kernels.git@master#egg=environment_kernels'

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
