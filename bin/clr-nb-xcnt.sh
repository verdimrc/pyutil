#!/usr/bin/env bash

SED=sed
if [[ $(uname) == 'Darwin' ]]; then
    SED=gsed
    if [[ $(which $SED) == '' ]]; then
        echo '[ERROR] Mac OSX requires gsed. Install with "brew install gsed"' >&2
        exit 1
    fi
fi

echo $SED -i 's/\(^  *"execution_count": \)[0-9][0-9]*,$/\1null,/g' "$1"
