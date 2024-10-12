#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

# Constants
GH=BurntSushi/ripgrep
DEB_NAME=ripgrep

latest_download_url() {
  local arch=$(uname -i) && [[ ${arch} == "x86_64" ]] && arch=amd64
  curl --silent "https://api.github.com/repos/${GH}/releases/latest"       |  # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/${DEB_NAME}_.*_${arch}.deb\"" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                              # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)  # https://github.com/.../14.1.1/ripgrep_14.1.1-1_amd64.deb
DEB=${DOWNLOAD_URL##*/}              # ripgrep_14.1.1-1_amd64.deb

VERSION_LATEST=${DEB#*_} ; VERSION_LATEST=${VERSION_LATEST%%_*}  # 14.1.1-1
VERSION_INSTALLED=$(dpkg-query -f '${Version}' -W ${DEB_NAME})   # 14.1.1-1
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

curl -Lo /tmp/${DEB} ${DOWNLOAD_URL}
sudo apt install -y /tmp/${DEB}
