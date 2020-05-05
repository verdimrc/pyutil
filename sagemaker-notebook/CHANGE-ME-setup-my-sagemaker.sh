#!/bin/bash

echo This is a sample. You should modify this script and run.

./adjust-sm-git.sh 'Firstname Lastname' first.last@email.com
./change-fontsize.sh
./patch-bash-profile.sh

# Recreate jupyter kernel for each of these custom environments.
./reinstall-ipykernel.sh ~/SageMaker/gluonts_p37
./reinstall-ipykernel.sh ~/SageMaker/ds_p37
