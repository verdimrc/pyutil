#!/bin/bash

cat << 'EOF' > ~/.jupyter/jupyter_notebook_config.py
import os

#c.NotebookApp.browser = 'chromium-browser'
#c.NotebookApp.terminado_settings = { "shell_command": ["/usr/bin/env", "bash"] }
c.NotebookApp.open_browser = False
c.NotebookApp.port_retries = 0
c.KernelSpecManager.ensure_native_kernel = False

# Needs: pip install environment_kernels
c.NotebookApp.kernel_spec_manager_class = 'environment_kernels.EnvironmentKernelSpecManager'
c.EnvironmentKernelSpecManager.find_conda_envs = False
c.EnvironmentKernelSpecManager.virtualenv_env_dirs = [os.path.expanduser('~/.pyenv/versions')]

c.FileCheckpoints.checkpoint_dir = '/tmp/.ipynb_checkpoints'
c.FileContentsManager.delete_to_trash = False
c.FileContentsManager.always_delete_dir = True
EOF


# JLab version since early Jul'22 switches to jupyter_server_config.py. However,
# let's retain jupyter_notebook_config.py too in case older jlab stack is used.
#
# See: https://jupyter-server.readthedocs.io/en/stable/operators/migrate-from-nbserver.html
sed 's/NotebookApp/ServerApp/g' ~/.jupyter/jupyter_notebook_config.py \
    >  ~/.jupyter/jupyter_server_config.py
