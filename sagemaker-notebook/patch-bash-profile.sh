#!/bin/bash

# This script patches /home/ec2-user/.bash_profile to always ensure Jupyter
# terminals start in the base environment, rather than JupyterSystemEnv conda
# environment.
#
# Without patched ~/.bash_profile: conda env list shows JupyterSystemEnv activated.
# With patched ~/.bash_profile: conda env list shows base activated.

cat << EOF >> /home/ec2-user/.bash_profile

# Workaround: when starting tmux from conda env, deactivate in all tmux sessions
# See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
[[ -z "\$TMUX" ]] || source deactivate

# Workaround: when starting jupyter lab from conda env, deactivate in all terminado sessions
# NOTE: similar treatment to tmux
[[ -z "\$JUPYTER_SERVER_ROOT" ]] || source deactivate
EOF

echo "On a new SageMaker terminal, which run 'sh' by default, type 'bash -l' (without the quotes)"
