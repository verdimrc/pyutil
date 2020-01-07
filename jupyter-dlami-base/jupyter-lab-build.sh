#!/bin/bash

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

# Not recommended, but in case user insists by setting a 'hidden' env var...
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

jupyter labextension list    # Show installed extensions
jupyter lab build            # Build extensions; slow...
jupyter labextension list    # Show built extensions
