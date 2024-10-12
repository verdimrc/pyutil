#!/bin/bash

set -u

# Constants
GH=o2sh/onefetch
TGZ=onefetch-linux.tar.gz

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |  # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/${TGZ}"               |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                        # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)  # https://github.com/.../download/2.22.0/onefetch-linux.tar.gz

VERSION_LATEST=${DOWNLOAD_URL##*/download/} ; VERSION_LATEST=${VERSION_LATEST%%/*}  # 2.22.0
VERSION_INSTALLED=$(onefetch --version | cut -d' ' -f2 2> /dev/null)
[[ ${VERSION_LATEST} == ${VERSION_INSTALLED} ]] && exit 0

curl -Lo /tmp/${TGZ} ${DOWNLOAD_URL}
sudo tar -xzf /tmp/${TGZ} --no-same-owner -C /usr/local/bin/ ./onefetch
