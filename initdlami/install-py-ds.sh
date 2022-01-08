#!/bin/bash

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

cat << 'EOF' >> ~/.bashrc

# PyEnv stuffs
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
pyenv rehash

# Note that these will have no effect if pyenv-virtualenv-init is enabled.
[[ -z "$TMUX" ]] || pyenv deactivate
[[ -z "$JUPYTER_SERVER_ROOT" ]] || pyenv deactivate
EOF

# Enable pyenv for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
pyenv rehash

# Miniconda3 to install pre-compiled python. Esp. on small instances like t* to
# reduce install time (and to conserve CPU credits).
pyenv install miniconda3-latest
CONDA=~/.pyenv/versions/miniconda3-latest/bin/conda
$CONDA update --yes -n base -c defaults conda

# Install jlab
$CONDA create --yes --name base-p310 python=3.10
pyenv virtualenv miniconda3-latest/envs/base-p310 jlab
declare -a PKGS=(
    jupyterlab
    jupyter-server-proxy
    jupyter_bokeh
    nbdime
    environment_kernels
    # jupyterlab_code_formatter requires formatters in its venv.
    # See: https://github.com/ryantam626/jupyterlab_code_formatter/issues/153
    jupyterlab_code_formatter
    black
    isort
)
~/.pyenv/versions/jlab/bin/pip install --no-cache-dir "${PKGS[@]}"

