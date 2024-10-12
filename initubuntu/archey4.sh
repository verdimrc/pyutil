#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

# Constants
GH=HorlogeSkynet/archey4
DEB_NAME=archey4

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest"   |  # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/${DEB_NAME}_.*_all.deb" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                          # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)  # https://github.com/.../v4.15.0.0/archey4_4.15.0.0-1_all.deb
DEB=${DOWNLOAD_URL##*/}              # archey4_4.15.0.0-1_all.deb

VERSION_LATEST=${DEB#*_} ; VERSION_LATEST=${VERSION_LATEST%%_*}  # 4.15.0.0-1
VERSION_INSTALLED=$(dpkg-query -f '${Version}' -W ${DEB_NAME})   # 4.15.0.0-1
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

curl -Lo /tmp/${DEB} ${DOWNLOAD_URL}
sudo apt install -y /tmp/${DEB}
