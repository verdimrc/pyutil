#!/bin/bash

# Constants
APP=bat
GH=sharkdp/bat

mkdir -p ~/.local/bin
cd ~/.local/bin

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/bat-.*-$(uname -i)-unknown-linux-gnu.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}


LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${LATEST_DOWNLOAD_URL##*/}
curl -LO ${LATEST_DOWNLOAD_URL}

# Go tarball has no root, so we need to create one
DIR=${TARBALL%.tar.gz}
tar -xzf $TARBALL && rm $TARBALL

[[ -L ${APP}-latest ]] && rm ${APP}-latest
ln -s $DIR ${APP}-latest
ln -s ${APP}-latest/${APP} .
