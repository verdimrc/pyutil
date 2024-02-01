#!/bin/bash

set -exuo pipefail

REPO_DIR=$1

(
    THIS_DIR=$(pwd)
    cd $REPO_DIR ;
    pwd ;
    PREFIX=$(basename $REPO_DIR)
    git archive --prefix=${PREFIX}/ -o ${THIS_DIR}/${PREFIX}-$(git rev-parse --short HEAD).zip HEAD ;
)
