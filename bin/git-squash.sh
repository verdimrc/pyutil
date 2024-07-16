#!/bin/bash

set -euo pipefail

declare -a HELP=(
    "[-h|--help]"
    "[-d|--dry-run]"
    "<root|COUNT for HEAD~count>"
)

COUNT=""
DRY_RUN=0

parse_args() {
    local key
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -h|--help)
            echo "Squash and set timestamp to latest."
            echo "Usage: $(basename ${BASH_SOURCE[0]}) ${HELP[@]}"
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=1
            shift
            ;;
        *)
            [[ $COUNT != "" ]] && { shift ; continue ; }
            COUNT="$1"
            shift
            ;;
        esac
    done

    [[ $COUNT != "" ]] || { echo "Missing COUNT for HEAD~count" ; exit -1 ; }
}

parse_args "$@"

TIMESTAMP=$(git show -s --pretty=tformat:%ai HEAD)

[[ $COUNT == "root" ]] \
    && GIT_REBASE_CMD="git rebase -i --root HEAD" \
    || GIT_REBASE_CMD="git rebase -i HEAD~${COUNT}"

echo "
TIMESTAMP=\$(git show -s --pretty=tformat:%ai HEAD)
${GIT_REBASE_CMD}
git commit --amend --no-edit --date=\"${TIMESTAMP}\"
git show --compact-summary HEAD

With vim editor, exit with :cq to inform this script that squash is aborted.
"

[[ $DRY_RUN == 1 ]] && exit 0

eval $GIT_REBASE_CMD
git commit --amend --no-edit --date="${TIMESTAMP}" && RETVAL=$? || RETVAL=$?
# NOTE: vim :cq will force abort this script

git show --compact-summary HEAD
