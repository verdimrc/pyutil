#!/bin/bash

echo 'Tested on DLAMI alinux'
echo 'Will update jupyter lab'


################################################################################
# Global environment

# A few useful packgages
sudo yum install -y tree htop

# locale information must be exported as environment variable (not just "normal"
# variable), otherwise 'jupyter labextension install ...' will give an error:
#     UnicodeDecodeError: 'ascii' codec can't decode byte ... in position ...
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

# Enable 'conda activate ...'
CONDAIFIED=$(grep '^\. \/home\/ec2-user\/anaconda3\/etc\/profile.d\/conda.sh' .bashrc | wc -l)
[[ ${CONDAIFIED} < 1 ]] && echo ". /home/ec2-user/anaconda3/etc/profile.d/conda.sh" >> ~/.bashrc
source /home/ec2-user/anaconda3/etc/profile.d/conda.sh


################################################################################
# jupyter

echo Python binary: $(which python)

# Update conda version
conda update -y -n base -c defaults anaconda conda

# Update jupyter lab
conda install -y nodejs
conda install -y -c conda-forge ipdb
conda update -y ipykernel notebook jupyter jupyter_client jupyter_console jupyter_core jupyterlab jupyterlab_launcher

# Install extensions
declare -a JUPYTER_EXT=(
    @jupyter-widgets/jupyterlab-manager @jupyterlab/toc
    @krassowski/jupyterlab_go_to_definition @bokeh/jupyter_bokeh
    @lckr/jupyterlab_variableinspector
)
for i in ${JUPYTER_EXT[@]}; do
    jupyter labextension install $i
done
# Show installed extensions
jupyter labextension list

echo "Changing a few settings in ~/.jupyter/jupyter_notebook_config.py"
[[ ! -f ~/.jupyter/jupyter_notebook_config.py ]] && jupyter lab --generate-config
sed -i \
    -e 's/^#c.NotebookApp.open_browser = True$/c.NotebookApp.open_browser = False/' \
    -e 's/^#c.NotebookApp.port_retries = .*$/c.NotebookApp.port_retries = 0/' \
    -e 's/^#c.KernelSpecManager.ensure_native_kernel = .*$/c.KernelSpecManager.ensure_native_kernel = False/' \
    ~/.jupyter/jupyter_notebook_config.py
egrep -v '^$|^#' ~/.jupyter/jupyter_notebook_config.py
