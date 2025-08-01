#!/bin/bash

# Constants
APP=rg
GH=BurntSushi/ripgrep

mkdir -p ~/.local/bin
cd ~/.local/bin

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/ripgrep-.*-$(uname -i)-unknown-linux-musl.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/' |                                       # Pluck JSON value
    grep '.tar.gz$'        # Ignore *.tar.gz.sha256
}

#ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz
LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${LATEST_DOWNLOAD_URL##*/}
curl -LO ${LATEST_DOWNLOAD_URL}

DIR=${TARBALL%.tar.gz}
tar -xzf $TARBALL ${DIR}/${APP} && rm $TARBALL
[[ -L ${APP} ]] && rm ${APP}
ln -s ${DIR}/${APP} ${APP} || true
