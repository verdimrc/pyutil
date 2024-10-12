#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

# Constants
APP=yq
GH=mikefarah/yq

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest"  |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/yq_linux_amd64.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)     # https://github.com/mikefarah/.../v4.44.3/yq_linux_amd64.tar.gz

VERSION_LATEST=${DOWNLOAD_URL%%/yq_linux*.tar.gz} ; VERSION_LATEST=${VERSION_LATEST##*/}    # v4.44.3
VERSION_INSTALLED=$(yq --version | cut -d' ' -f4)
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

TGZ=${DOWNLOAD_URL##*/}
curl -Lo /tmp/${TGZ} ${DOWNLOAD_URL}
sudo tar -xzf /tmp/${TGZ} --no-same-owner -C /tmp/ ./yq_linux_amd64 yq.1
sudo mv /tmp/${TGZ%%.*} /usr/local/bin/yq   # /tmp/yq_linux_amd64 => /usr/local/bin/yq
sudo mkdir -p /usr/local/share/man/man1/
sudo mv /tmp/yq.1 /usr/local/share/man/man1/
