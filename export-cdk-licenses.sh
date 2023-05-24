#!/usr/bin/env bash

set -eo pipefail


################################################################################
# Deal with OSX quirkiness
################################################################################
# Utility function to get script's directory (deal with Mac OSX quirkiness).
# This function is ambidextrous as it works on both Linux and OSX.
get_bin_dir() {
    local READLINK=readlink
    if [[ $(uname) == 'Darwin' ]]; then
        READLINK=greadlink
        if [ $(which greadlink) == '' ]; then
            echo '[ERROR] Mac OSX requires greadlink. Install with "brew install greadlink"' >&2
            exit 1
        fi
    fi

    local BIN_DIR=$(dirname "$($READLINK -f ${BASH_SOURCE[0]})")
    echo -n ${BIN_DIR}
}

CP=cp
if [[ $(uname) == 'Darwin' ]]; then
    CP=gcp
    if [ $(which gcp) == '' ]; then
        echo '[ERROR] Mac OSX requires gcp. Install with "brew install coreutils"' >&2
        exit 1
    fi
fi
################################################################################


cd $(get_bin_dir)
GITROOT=$(git rev-parse --show-toplevel)
cd $GITROOT
declare -a LICENSE_FILES=( $(npx license-checker --relativeLicensePath | grep licenseFile | awk '{print $NF}') )

mkdir -p package-licenses/
for i in "${LICENSE_FILES[@]}"; do
    $CP --parents "$i" package-licenses/
done

