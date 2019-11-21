#!/bin/bash

echo 'Tested on DLAMI alinux'
echo 'Will update jupyter lab on pytorch_p36 conda environment'


################################################################################
# One time per EC2

# A few useful packgages
sudo yum install tree htop

# locale information must be exported as environment variable (not just "normal"
# variable), otherwise 'jupyter labextension install ...' will give an error:
#     UnicodeDecodeError: 'ascii' codec can't decode byte ... in position ...
if [[ $(printenv LANG) == '' ]]; then
    export LANG=en_US.utf-8
    echo 'export LANG=en_US.utf-8' >> ~/.bashrc
fi

if [[ $(printenv LC_ALL) == '' ]]; then
    export LC_ALL=${LANG}
    echo 'export LC_ALL=${LANG}' >> ~/.bashrc
fi

# Enable 'conda activate ...'
CONDAIFIED=$(grep '^\. \/home\/ec2-user\/anaconda3\/etc\/profile.d\/conda.sh' .bashrc | wc -l)
[[ ${CONDAIFIED} < 1 ]] && echo ". /home/ec2-user/anaconda3/etc/profile.d/conda.sh" >> ~/.bashrc
. /home/ec2-user/anaconda3/etc/profile.d/conda.sh


################################################################################
# One time per environment: update jupyter

conda activate pytorch_p36

# Update jupyter lab
conda install nodejs
conda update notebook jupyter jupyter_client jupyter_console jupyter_core jupyterlab jupyterlab_launcher

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

conda deactivate

echo "Changing a few settings in ~/.jupyter/jupyter_notebook_config.py"
[[ ! -f ~/.jupyter/jupyter_notebook_config.py ]] && jupyter lab --generate-config
sed -i \
    -e 's/^#c.NotebookApp.open_browser = True$/c.NotebookApp.open_browser = True/' \
    -e 's/^#c.NotebookApp.port_retries = .*$/c.NotebookApp.port_retries = 0/' \
    ~/.jupyter/jupyter_notebook_config.py
egrep -v '^$|^#' ~/.jupyter/jupyter_notebook_config.py
