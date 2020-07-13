#!/bin/bash

cat << EOF >> /home/ec2-user/.bash_profile

# Workaround: when starting tmux from conda env, deactivate in all tmux sessions
# See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
if [[ ! -z "\$TMUX" ]]; then
    for i in \$(seq \$CONDA_SHLVL); do
        conda deactivate
    done
fi

git_branch() {
   local branch=\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
   [[ "\$branch" == "" ]] && echo "" || echo "(\$branch) "
}

export PS1='[\w] \$(git_branch)\\$ '
EOF

echo "On a new SageMaker terminal, which uses 'sh' by default, type 'bash -l' (without the quotes)"
