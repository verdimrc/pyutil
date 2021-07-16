#!/bin/bash -e

################################################################################
# Detect DL AMI
################################################################################
is_dlami_base() {
    grep 'Deep Learning Base AMI (Amazon Linux' /etc/motd &> /dev/null
    local -i retval=$?
    [[ $retval -eq 0 ]] && echo true || echo false
}

is_dlami_conda() {
    grep 'Deep Learning AMI (Amazon Linux' /etc/motd &> /dev/null
    local -i retval=$?
    [[ $retval -eq 0 ]] && echo true || echo false
}

dlami_type() {
    if [[ $(is_dlami_base) == 'true' ]]; then
        echo DLAMI_BASE
    elif [[ $(is_dlami_conda) == 'true' ]]; then
        echo DLAMI_CONDA
    fi
}

declare DLAMI_TYPE=$(dlami_type)
if [[ $DLAMI_TYPE == '' ]]; then
    echo Cannot detect DLAMI_CONDA or DLAMI_BASE. Exiting... >&2
    exit 1
fi

echo Detected $DLAMI_TYPE


################################################################################
# Locale information (for older DLAMI)
################################################################################
# Locale information must be exported as environment variable (not just "normal"
# variable), otherwise 'jupyter labextension install ...' will give an error:
#     UnicodeDecodeError: 'ascii' codec can't decode byte ... in position ...
#
# NOTE: this happens only on older DLAMI. Newer DLAMI already sets the locale.
if [[ $(printenv LANG) == '' ]]; then
    export LANG=en_US.utf-8
    echo 'export LANG=en_US.utf-8' >> ~/.bashrc
    # To silent warning in welcome banner
    sudo sh -c "echo 'LANG=en_US.utf-8' >> /etc/environment"
fi

if [[ $(printenv LC_ALL) == '' ]]; then
    export LC_ALL=${LANG}
    echo 'export LC_ALL=${LANG}' >> ~/.bashrc
    # To silent warning in welcome banner
    sudo sh -c "echo 'LC_ALL=en_US.utf-8' >> /etc/environment"
fi


################################################################################
# Install conda if we're running on DLAMI_BASE
################################################################################
mimic_dlami_conda() {
    # Install miniconda3, but somewhat masquerade as anaconda3
    local CONDA_SRC=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    if [[ $# -eq 0 ]]; then
        echo Downloading miniconda3 from $CONDA_SRC
        curl -O $CONDA_SRC
    else
        CONDA_SRC=$1
        echo Downloading miniconda3 from $CONDA_SRC
        aws s3 cp $CONDA_SRC .
    fi
    local CONDA_INSTALLER=$(basename $CONDA_SRC)
    chmod ugo+x $CONDA_INSTALLER
    echo Installing miniconda3 from $CONDA_INSTALLER
    ./$CONDA_INSTALLER -b -p ~/anaconda3
    rm ./$CONDA_INSTALLER

    # Mimic .bash_profile
    [[ ! -f ~/.bash_profile ]] && cat << EOF > ~/.bash_profile
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=\$PATH:\$HOME/.local/bin:\$HOME/bin

export PATH
EOF

    # First-time setup for conda
    conda update -y -n base --all
    conda config --add channels conda-forge
    conda config --set auto_activate_base false
}

[[ $DLAMI_TYPE == DLAMI_BASE ]] && mimic_dlami_conda "$@"


################################################################################
# One-time setup for conda
################################################################################
# Workarounds for messed-up PATH etc. (due to these app source ~/.bash_profile again):
# - when starting tmux from a conda env, tmux sessions should reset to base
#   See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
# - when starting jupyter from a conda env, terminado sessions should reset to base
cat << EOF >> ~/.bash_profile

# Workaround: when starting tmux from conda env, deactivate in all tmux sessions
# See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
if [[ ! -z "\$TMUX" ]]; then
    for i in \$(seq \$CONDA_SHLVL); do
        conda deactivate
    done
fi

# Workaround: when starting jupyter lab from conda env, deactivate in all terminado sessions
# NOTE: similar treatment to tmux
if [[ ! -z "\$JUPYTER_SERVER_ROOT" ]]; then
    for i in \$(seq \$CONDA_SHLVL); do
        conda deactivate
    done
fi
EOF


################################################################################
# Clean-up
################################################################################
#conda clean --all -y  # Very slow...
rm -fr /tmp/yarn* /tmp/npm*
