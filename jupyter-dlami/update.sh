#!/bin/bash

echo 'Tested on DLAMI alinux'
echo 'Will update jupyter lab and extensions on pytorch_p36 conda environment'

sudo yum update

# Update jupyter lab
conda activate pytorch_p36
conda update nodejs notebook jupyter jupyter_client jupyter_console jupyter_core jupyterlab jupyterlab_launcher

# Update extensions
declare -a JUPYTER_EXT=( $(jupyter labextension list 2>&1 | grep '^  *@' | awk '{print $1}') )
for i in ${JUPYTER_EXT[@]}; do
    jupyter labextension update $i
done

# Show installed extensions
jupyter labextension list

conda deactivate
