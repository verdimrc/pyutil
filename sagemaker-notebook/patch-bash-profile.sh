#!/bin/bash

# 1) This script patches /home/ec2-user/.bash_profile to always ensure Jupyter
# terminals start in the base environment, rather than JupyterSystemEnv conda
# environment.
#
# Without patched ~/.bash_profile: conda env list shows JupyterSystemEnv activated.
# With patched ~/.bash_profile: conda env list shows base activated.
#
# 2) Change PS1 to show only full pwd and git branch (username always ec2-user
# anyway, and the private IP address is not use that frequently.

cat << EOF >> /home/ec2-user/.bash_profile

# Workaround: when starting tmux from conda env, deactivate in all tmux sessions
# See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
[[ -z "\$TMUX" ]] || conda deactivate

# Workaround: when starting jupyter lab from conda env, deactivate in all terminado sessions
# NOTE: similar treatment to tmux
[[ -z "\$JUPYTER_SERVER_ROOT" ]] || conda deactivate

git_branch() {
   local branch=\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
   [[ "\$branch" == "" ]] && echo "" || echo "(\$branch) "
}

export PS1='[\w] \$(git_branch)\\$ '
EOF

echo "On a new SageMaker terminal, which uses 'sh' by default, type 'bash -l' (without the quotes)"
