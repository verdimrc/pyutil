#!/bin/bash

cat << 'EOF' >> ~/.bash_profile

# When starting tmux or jlab from conda env, weird stuffs wrt. python may happen.
# See: https://github.com/conda/conda/issues/6826#issuecomment-471240590
[[ ! (-z "$TMUX" || -z "$CONDA_SHLVL") ]] \
    && echo "WARNING: tmux was started from a conda env"

# Same treatment needed for jlab
[[ ! (-z "$JUPYTER_SERVER_ROOT" || -z "$CONDA_SHLVL") ]] \
    && echo "WARNING: JLab was started from a conda env"

# Same treatement when virtual-env in effect
[[ ! (-z "$TMUX" || -z "$VIRTUAL_ENV") ]] \
    && echo "WARNING: tmux was started from a virtual env"

# Same treatment needed for jlab
[[ ! (-z "$JUPYTER_SERVER_ROOT" || -z "$VIRTUAL_ENV") ]] \
    && echo "WARNING: JLab was started from a virtual env"
EOF


# PS1 must preceed conda bash.hook, to correctly display CONDA_PROMPT_MODIFIER
cp ~/.bashrc{,.ori}
cat << EOF > ~/.bashrc
git_branch() {
   local branch=\$(/usr/bin/git branch 2>/dev/null | grep '^*' | colrm 1 2)
   [[ "\$branch" == "" ]] && echo "" || echo "(\$branch) "
}

# All colors are bold
COLOR_GREEN="\[\033[1;32m\]"
COLOR_PURPLE="\[\033[1;35m\]"
COLOR_YELLOW="\[\033[1;33m\]"
COLOR_OFF="\[\033[0m\]"

# Define PS1 before conda bash.hook, to correctly display CONDA_PROMPT_MODIFIER
export PS1="[\$COLOR_GREEN\w\$COLOR_OFF] \$COLOR_PURPLE\\\$(git_branch)\$COLOR_OFF\\\$ "

EOF


# Original .bashrc content
cat ~/.bashrc.ori >> ~/.bashrc

# Custom aliases
cat << EOF >> ~/.bashrc

alias ll='ls -alF --color=auto'
EOF
