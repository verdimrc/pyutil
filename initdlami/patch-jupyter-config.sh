#!/bin/bash

try_append() {
    local key="$1"
    local value="$2"
    local msg="$3"

    HAS_KEY=$(grep "^$key" ~/.jupyter/jupyter_notebook_config.py | wc -l)

    if [[ $HAS_KEY > 0 ]]; then
        echo "Skip adding $key because it already exists in $HOME/.jupyter/jupyter_notebook_config.py"
        return 1
    fi

    echo "$key = $value" >> ~/.jupyter/jupyter_notebook_config.py
    echo $msg
}

try_append \
    c.NotebookApp.open_browser \
    "False" \
    "Do not auto-open browser"

try_append \
    c.EnvironmentKernelSpecManager.conda_env_dirs \
    "['/home/ec2-user/anaconda3/envs']" \
    "Register additional prefixes for conda environments"

try_append \
    c.EnvironmentKernelSpecManager.virtualenv_env_dirs \
    "['/home/ec2-user/.pyenv/versions']" \
    "Register additional prefixes for virtualenv environments"
