#!/bin/bash

echo On your SageMaker notebook, store this file under ~/Sagemaker and set as executable.
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
#git config --global alias.lola "lol --all"  # SageMaker's git does not support alias chain :(
git config --global alias.lola "! git lol --all"
git config --global alias.lolc "! clear; git lol -\$(expr \`tput lines\` '*' 2 / 3)"
git config --global alias.lolac "! clear; git lol --all -\$(expr \`tput lines\` '*' 2 / 3)"

# Needed when notebook instance is not configured with a code repository.
echo Setup steps for HTTPS connections to AWS CodeCommit repositories
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
