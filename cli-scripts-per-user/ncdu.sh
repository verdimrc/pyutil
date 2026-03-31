#!/bin/bash

mkdir -p ~/.local/bin
cd ~/.local/bin

DOWNLOAD_TAG=$(curl -L https://dev.yorhel.nl/ncdu | grep "/download/ncdu-.*-linux-$(uname -i).tar.gz")
# - <a href="/download/ncdu-2.9.1-x86_64.tar.gz">x86_64</a>

DOWNLOAD_RELPATH=$(echo $DOWNLOAD_TAG | sed 's/.*"\(.*.tar.gz\).*$/\1/')  # Take /download/ncdu-2.9.1-x86_64.tar.gz
curl -LO https://dev.yorhel.nl/$DOWNLOAD_RELPATH
TARBALL=${DOWNLOAD_RELPATH##*/}
tar -xzf $TARBALL
rm $TARBALL
