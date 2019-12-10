#!/bin/bash

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
# A few useful packages
################################################################################
sudo yum install -y tree htop fio
sudo yum clean all

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

    # Mimic .dlamirc
#     cat << EOF > .dlamirc
# export PATH=$HOME/anaconda3/bin/:/usr/libexec/gcc/x86_64-redhat-linux/7:/usr/local/cuda/bin:/usr/local/bin:/opt/aws/bin:/home/ec2-user/src/cntk/bin:/usr/local/mpi/bin:$PATH
# export LD_LIBRARY_PATH=/lib:/usr/local/cuda/lib64:/usr/local/lib:/usr/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/efa/lib:/usr/local/cuda/lib:/opt/amazon/efa/lib64:/usr/local/mpi/lib:$LD_LIBRARY_PATH
# export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
# export LD_LIBRARY_PATH_WITH_DEFAULT_CUDA=/usr/lib64/openmpi/lib/:/usr/local/cuda/lib64:/usr/local/lib:/usr/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/mpi/lib:/lib/:/usr/local/cuda-9.0/lib/:$LD_LIBRARY_PATH_WITH_DEFAULT_CUDA
# export LD_LIBRARY_PATH_WITHOUT_CUDA=/usr/lib64/openmpi/lib/:/usr/local/lib:/usr/lib:/usr/local/mpi/lib:/lib/:$LD_LIBRARY_PATH_WITHOUT_CUDA
# export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib/:/usr/local/cuda/lib64:/usr/local/lib:/usr/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/mpi/lib:/lib/:$LD_LIBRARY_PATH
# EOF
    local CONDAIFIED=$(grep '^export PATH=\$HOME\/anaconda3\/bin\/:.*$' .dlamirc | wc -l)
    [[ $CONDAIFIED < 1 ]] && echo 'export PATH=$HOME/anaconda3/bin/:/usr/libexec/gcc/x86_64-redhat-linux/7:$PATH' >> .dlamirc
    source ~/.dlamirc

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

    # Mimic .profile
    [[ ! -f ~/.profile ]] && cat << EOF > ~/.profile
export PATH=\$HOME/anaconda3/bin/:\$PATH
EOF

    # First-time setup for conda
    conda config --add channels conda-forge
    conda config --set auto_activate_base false
}

mimic_dlami_conda "$@"


################################################################################
# One-time setup for conda
################################################################################
# Enable 'conda activate ...'
CONDAIFIED=$(grep '^\. \/home\/ec2-user\/anaconda3\/etc\/profile.d\/conda.sh' .bashrc | wc -l)
[[ ${CONDAIFIED} < 1 ]] && echo ". /home/ec2-user/anaconda3/etc/profile.d/conda.sh" >> ~/.bashrc
source /home/ec2-user/anaconda3/etc/profile.d/conda.sh

# Workarounds for messed-up PATH etc. (due to these app source ~/.bash_profile again):
# - when starting tmux from a conda env, tmux sessions should reset to base
#   See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
# - when starting jupyter from a conda env, terminado sessions should reset to base
cat << EOF >> .bash_profile

# Workaround: when starting tmux from conda env, deactivate in all tmux sessions
# See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
[[ -z "\$TMUX" ]] || conda deactivate

# Workaround: when starting jupyter lab from conda env, deactivate in all terminado sessions
# NOTE: similar treatment to tmux
[[ -z "\$JUPYTER_SERVER_ROOT" ]] || conda deactivate
EOF

# Update base environment
conda update -y -n base --all


################################################################################
# Jupyter
################################################################################
# Dedicated conda environment jupyter-lab environment, with newer Python.
declare -a JUPYTER_PKGS=(
    nodejs nb_conda_kernels ipywidgets ipykernel notebook jupyter jupyter_client
    jupyter_console jupyter_core jupyterlab jupyterlab_launcher ipympl
)
conda create -y -n jupyterlab python=3.8 "${JUPYTER_PKGS[@]}"
conda activate jupyterlab

# Configure jupyter lab
echo "Changing a few settings in ~/.jupyter/jupyter_notebook_config.py"
[[ ! -f ~/.jupyter/jupyter_notebook_config.py ]] && jupyter lab --generate-config
sed -i \
    -e 's/^#c.NotebookApp.open_browser = True$/c.NotebookApp.open_browser = False/' \
    -e 's/^#c.NotebookApp.port_retries = .*$/c.NotebookApp.port_retries = 0/' \
    -e 's/^#c.KernelSpecManager.ensure_native_kernel = .*$/c.KernelSpecManager.ensure_native_kernel = False/' \
    ~/.jupyter/jupyter_notebook_config.py
cat << EOF >> ~/.jupyter/jupyter_notebook_config.py
c.CondaKernelSpecManager.env_filter='jupyterlab'
c.CondaKernelSpecManager.name_format='{1}'
EOF

# Fix terminal environment being messed-up due to starting `jupyter lab` from the conda environment.
# When a new terminal starts, the prompt does not show (jupyterlab) even though this env is somewhat active,
# and users must always have to `conda deactivate` first before activate another env, otherwise the activation
# won't be correct, i.e., messed-up PYTHONPATH, etc.
#
# The bash_wrapper essentially forces deactivate before starting the shell. 
cat << EOF > ~/bash_wrapper
#!/usr/bin/bash
source deactivate &> /dev/null
exec bash
EOF
chmod ugo+x ~/bash_wrapper

# Show jupyter-lab configuration
egrep -v '^$|^#' ~/.jupyter/jupyter_notebook_config.py

# Install extensions
echo "Installing jupyter-lab extensions may take 10+ minutes..."
declare -a JUPYTER_EXT=(
    @jupyter-widgets/jupyterlab-manager @jupyterlab/toc
    @krassowski/jupyterlab_go_to_definition @lckr/jupyterlab_variableinspector
    @mflevine/jupyterlab_html
    jupyter-matplotlib @bokeh/jupyter_bokeh plotlywidget jupyterlab-plotly 
    #@jupyterlab/plotly-extension
)
for i in ${JUPYTER_EXT[@]}; do
    cmd="jupyter labextension install $i --no-build"
    echo $cmd
    eval $cmd
done

# Not recommended, but in case user insists...
if [[ $INSTALL_JUPYTERLAB_LSP == 'true' ]]; then
    echo '###############################################'
    echo '# WARNING @@@ WARNING @@@ WARNING @@@ WARNING #'
    echo '###############################################'
    echo '# jupyterlab-lsp is slow, hog CPU, and buggy. #'
    echo '# Install at your own risk.                   #'
    echo '###############################################'
    pip install --pre jupyter-lsp
    conda install -c conda-forge -y python-language-server
    echo jupyter labextension install @krassowski/jupyterlab-lsp --no-build
    jupyter labextension install @krassowski/jupyterlab-lsp --no-build
fi

# Build the extensions
jupyter lab build
# Show installed extensions
jupyter labextension list

conda deactivate

# Clean-up
conda clean --all -y
rm -fr /tmp/yarn* /tmp/npm*


################################################################################
# Jupyter per-user settings
################################################################################
USER_SETTINGS_DIR=~/.jupyter/lab/user-settings/@jupyterlab
mkdir -p $USER_SETTINGS_DIR/{fileeditor,notebook,terminal}-extension

cat << EOF > $USER_SETTINGS_DIR/fileeditor-extension/plugin.jupyterlab-settings
{
    "editorConfig": {
        "rulers": [80, 120],
        "codeFolding": true
    }
}
EOF

cat << EOF > $USER_SETTINGS_DIR/notebook-extension/tracker.jupyterlab-settings
{
    "codeCellConfig": {
        "rulers": [80, 120],
        "codeFolding": false
    },
    "markdownCellConfig": {
        "rulers": [80, 120],
        "codeFolding": false
    },
    "rawCellConfig": {
        "rulers": [80, 120],
        "codeFolding": false
    }
}
EOF

cat << EOF > $USER_SETTINGS_DIR/terminal-extension/plugin.jupyterlab-settings
{
    "theme": "dark"
}
EOF


################################################################################
# Recommended conda environment for actual workJupyter
################################################################################
echo '#################################################################'
echo '# Sample conda environment for actual work -- for display only. #'
echo "# You'll need to run the next command by yourself.              #"
echo '#################################################################'
declare -a DS_PKG=(
    ipykernel ipdb ipywidgets s3fs sagemaker-python-sdk
    pandas scikit-learn pandas-profiling xgboost
    matplotlib seaborn bokeh plotly orca
)
echo conda create -n ds_p37 -c conda-forge python=3.7 "${DS_PKG[@]}"
echo conda install -n ds_p37 -c plotly plotly-orca
