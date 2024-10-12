#!/bin/bash

echo Usage: ${BASH_SOURCE[0]} '"<user_name>"' email@address.com
echo

set_git_user() {
    local USER_NAME="$1"
    local USER_EMAIL=$2

    if [[ "$USER_NAME" != "" ]]
    then
        git config --global user.name "$USER_NAME"
    fi

    if [[ "$USER_EMAIL" != "" ]]
    then
        git config --global user.email $USER_EMAIL
    fi

    if [[ "$USER_NAME""$USER_EMAIL" != "" ]]
    then
        echo Global Git\'s name / email = $(git config --global user.name) / $(git config --global user.email)
        echo You may need to run: git commit --amend --reset-author
    fi
}

set_git_user "$@"

echo 'Set editor to /usr/bin/vim (for DL AMI)'
git config --global core.editor /usr/bin/vim

echo 'Set default branch to main'
git config --global init.defaultBranch main

echo Adjusting log aliases...
git config --global alias.lol "log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold white)— %an%C(reset)%C(bold yellow)%d%C(reset)' --abbrev-commit --date=relative"
git config --global alias.lolc "! clear; git lol -\$(expr \`tput lines\` '*' 2 / 3)"
git config --global alias.lola "lol --all"
git config --global alias.lolac "lolc --all"

echo Cache git credential for 4h
git config --global credential.helper 'cache --timeout=14400'

if command -v delta &> /dev/null ; then
    echo "adjust-git.sh: delta is available..."
    git config --global core.pager "delta -s"
    git config --global interactive.diffFilter "delta -s --color-only"
    git config --global delta.navigate "true"

    # https://github.com/dandavison/delta/discussions/1461#discussion-5342765
    git config --global delta.wrap-max-lines unlimited
    git config --global delta.wrap-right-percent 1
    git config --global delta.wrap-left-symbol " "
fi
