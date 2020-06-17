#!/bin/bash

HAS_TERMINADO_SETTING=$(grep '^c.NotebookApp.terminado_settings' ~/.jupyter/jupyter_notebook_config.py | wc -l)

if [[ $HAS_TERMINADO_SETTING > 0 ]]; then
    echo "Ignore setting shell to bash, because $HOME/.jupyter/jupyter_notebook_config.py has c.NotebookApp.terminado_settings."
    exit
fi

echo "c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" >> ~/.jupyter/jupyter_notebook_config.py

echo 'Changed SageMaker jupyter notebook shell to /bin/bash'
echo 'To enforce the change to bash shell: sudo initctl restart jupyter-server --no-wait'
