#!/bin/bash -xe

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
    conda update -y -n base --all
    conda config --add channels conda-forge
    conda config --set auto_activate_base false
}

[[ $DLAMI_TYPE == DLAMI_BASE ]] && mimic_dlami_conda "$@"


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


################################################################################
# Jupyter
################################################################################
# Dedicated conda environment jupyter-lab environment, with newer Python.
declare -a JUPYTER_PKGS=(
    nodejs nb_conda_kernels ipywidgets ipykernel notebook jupyter jupyter_client
    jupyter_console jupyter_core jupyterlab jupyterlab_launcher ipympl
)
conda create -y -n jupyterlab -c conda-forge python=3.8 "${JUPYTER_PKGS[@]}"
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

# Show jupyter-lab configuration
egrep -v '^$|^#' ~/.jupyter/jupyter_notebook_config.py

# Install extensions in the background, detached from this script
echo "jupyter-lab-ext: install in background"
echo "jupyter-lab-ext: may take 10+ minutes to complete"
echo 'Please check status at jupyter-lab-ext.{log,INSTALLING,SUCCESS,FAILED}.'
touch jupyter-lab-ext.INSTALLING
nohup bash -c '
export PATH=/home/ec2-user/anaconda3/envs/jupyterlab/bin:$PATH
echo JUPYTER_BIN=$(which jupyter)
./jupyter-lab-build.sh && touch jupyter-lab-ext.SUCCESS || touch jupyter-lab-ext.FAILED' \
    &> jupyter-lab-ext.log </dev/null &

conda deactivate


################################################################################
# Remove python2 environments if we're running on DLAMI_BASE
################################################################################
# First, pre-warm the EBS (b/c this AMI is restored from snapshot located in S3)
strip_stock_dlami() {
    local PYTHON2_ENV=(
        chainer_p27 mxnet_p27 python2 pytorch_p27 tensorflow_p27 tensorflow2_p27
    )

    local p2
    for p2 in "${PYTHON2_ENV[@]}"; do
        echo Removing conda environment ${p2}
        rm -fr /home/ec2-user/anaconda3/envs/${p2}
    done
}

[[ $DLAMI_TYPE == DLAMI_CONDA ]] && strip_stock_dlami


################################################################################
# Clean-up
################################################################################
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
echo "# You'll need to run the next stanza by yourself.               #"
echo '#################################################################'
LONG_STRING=$(cat << EOF
declare -a DS_PKG=(
    ipdb s3fs sagemaker-python-sdk

    # Needed by my vscode setup
    jupyter autoflake black pydocstyle flake8 mypy isort tox

    # Basic DS stuffs. 
    mkl "libblas=*=*mkl"   # prefer mkl over openblas for numpy. Comment to prefer openblas
    pandas scikit-learn xgboost pandas-profiling

    # Dependencies for eda-viz, featexp, pydqc
    matplotlib matplotlib-venn seaborn xlsxwriter openpyxl

    # One of NLP toolkits.
    spacy spacy-model-en_core_web_sm
)
MY_CONDA_ENV=ds_p37
conda create -n \${MY_CONDA_ENV} --yes -c conda-forge python=3.7 "\${DS_PKG[@]}"

# Lock numpy to mkl in the event of 'conda update --all'
# See: https://github.com/conda-forge/numpy-feedstock/issues/153#issuecomment-513943382
echo >> ~/anaconda3/envs/\${MY_CONDA_ENV}/conda-meta/pinned

~/anaconda3/envs/\${MY_CONDA_ENV}/bin/pip install pydqc

# These packages lock dependencies down to minor version, so skip the deps.
~/anaconda3/envs/\${MY_CONDA_ENV}/bin/pip install --no-deps featexp eda-viz
EOF
)
echo "$LONG_STRING"


################################################################################
# Misc. finale
################################################################################
echo
echo "###########################################"
echo "# [OPTIONAL] Pre-warm the root EBS volume #"
echo "###########################################"
echo "See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-initialize.html"
echo "sudo fio --filename=/dev/nvme0n1 --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize"
echo
echo "jupyter lab installation may still run in background"
echo "It may take may take 10+ minutes to complete"
echo "Please check jupyter-lab-ext.{log,INSTALLING,SUCCESS,FAILED}"
