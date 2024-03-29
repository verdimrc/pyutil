#### initubuntu additions from here onwards ####
git_branch() {
   local branch=$(/usr/bin/git branch 2>/dev/null | grep '^*' | colrm 1 2)
   [[ "$branch" == "" ]] && echo "" || echo "($branch) "
}

# All colors are bold
COLOR_GREEN="\[\033[1;32m\]"
COLOR_PURPLE="\[\033[1;35m\]"
COLOR_YELLOW="\[\033[1;33m\]"
COLOR_BLUE="\[\033[01;34m\]"
COLOR_OFF="\[\033[0m\]"

prompt_prefix() {
    # VScode calls pyenv shell instead of pyenv activate.
    if [[ (${TERM_PROGRAM} == "vscode") && (! -v VIRTUAL_ENV) && (-v PYENV_VERSION) ]]; then
        echo -n "($PYENV_VERSION) "
    fi
}

# Define PS1 before conda bash.hook, to correctly display CONDA_PROMPT_MODIFIER
#export PS1="\$(prompt_prefix)[$COLOR_GREEN\w$COLOR_OFF] $COLOR_PURPLE\$(git_branch)$COLOR_OFF\$ "
export PS1="\$(prompt_prefix)[$COLOR_BLUE\u@\h$COLOR_OFF:$COLOR_GREEN\w$COLOR_OFF] $COLOR_PURPLE\$(git_branch)$COLOR_OFF\$ "

man() {
	env \
		LESS_TERMCAP_mb=$(printf "\e[1;31m") \
		LESS_TERMCAP_md=$(printf "\e[1;31m") \
		LESS_TERMCAP_me=$(printf "\e[0m") \
		LESS_TERMCAP_se=$(printf "\e[0m") \
		LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
		LESS_TERMCAP_ue=$(printf "\e[0m") \
		LESS_TERMCAP_us=$(printf "\e[1;32m") \
		man "$@"
}

# Custom aliases
alias ll='ls -alF --color=auto'

export DSTAT_OPTS="-cdngym"
