#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

# Constants
GH=sharkdp/bat
DEB_NAME=bat-musl

ARCH=$(uname -i) && [[ ${ARCH} == "x86_64" ]] && ARCH=amd64

latest_download_url() {
  local arch=$(uname -i) && [[ ${arch} == "x86_64" ]] && arch=amd64
  curl --silent "https://api.github.com/repos/${GH}/releases/latest"       |  # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/${DEB_NAME}_.*_${arch}.deb" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                              # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)  # https://github.com/.../bat-musl_0.24.0_amd64.deb
DEB=${DOWNLOAD_URL##*/}              # bat-musl_0.24.0_amd64.deb

VERSION_LATEST=${DEB#*_} ; VERSION_LATEST=${VERSION_LATEST%%_*}  # 0.24.0
VERSION_INSTALLED=$(dpkg-query -f '${Version}' -W ${DEB_NAME})   # 0.24.0
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

curl -Lo /tmp/${DEB} ${DOWNLOAD_URL}
sudo apt install -y /tmp/${DEB}
