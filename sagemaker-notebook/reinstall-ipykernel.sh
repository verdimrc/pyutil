#!/bin/bash

# This script registered a conda environment located in ~/SageMaker to the
# Jupyter server in the SageMaker notebook instance.
#
# Target use-case: a conda environment is installed under ~/SageMaker to make
# the environment survives reboots. However, in the next cycle, this custom
# environment must be registered again (since that kernel information is
# stored outside ~/SageMaker hence lost during reboot.

exit_on_error() {
    echo "$@" >&2
    exit 1
}

[[ $# -lt 1 ]] && exit_on_error "Usage: ${BASH_SOURCE[0]} <path_to_custom_conda_env>"

ENV_DIR=.
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -h|--help)
        echo "Usage: ${BASH_SOURCE[0]} <path_to_custom_conda_env>"
        exit 0
        ;;
    *)
        ENV_DIR=$(readlink -e $key)
        [[ ! $? -eq 0 ]] && exit_on_error "Invalid Path: $key"
        break
        ;;
    esac
done

PYBIN=$ENV_DIR/bin/python
[[ ! -f $ENV_DIR/bin/python ]] && exit_on_error "Couldn't find $PYBIN"

ENV_NAME=${ENV_DIR##*/}
cmd="$PYBIN -m ipykernel install --user --name $ENV_NAME"
echo $cmd
eval $cmd
