#!/bin/bash

# Constants
APP=bat
GH=sharkdp/bat

mkdir -p ~/.local/bin
cd ~/.local/bin

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" | # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*$(uname -i)-unknown-linux-musl.tar.gz" | # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                                      # Pluck JSON value
}

LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${APP}-${LATEST_DOWNLOAD_URL##*/${APP}-}
curl -LO ${LATEST_DOWNLOAD_URL}
tar -xzf $TARBALL && rm $TARBALL
DIR=${TARBALL%.tar.gz}

[[ -L ${APP}-latest ]] && rm ${APP}-latest
ln -s $DIR ${APP}-latest
ln -s ${APP}-latest/${APP} .

cat << 'EOF' >> ~/.bashrc
source ~/.local/bin/bat-latest/autocomplete/bat.bash
EOF
