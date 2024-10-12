#!/bin/bash

set -u

# Constants
GH=o2sh/onefetch
DEB_NAME=onefetch

latest_download_url() {
  local arch=$(uname -i) && [[ ${arch} == "x86_64" ]] && arch=amd64
  curl --silent "https://api.github.com/repos/${GH}/releases/latest"       |  # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/${DEB_NAME}_.*_${arch}.deb" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                              # Pluck JSON value
}

LATEST_DOWNLOAD_URL=$(latest_download_url)  # https://github.com/.../onefetch_2.22.0_amd64.deb
DEB=${LATEST_DOWNLOAD_URL##*/}              # onefetch_2.22.0_amd64.deb
VERSION_LATEST=${DEB#*_} ; VERSION_LATEST=${VERSION_LATEST%%_*}  # 2.22.0
VERSION_INSTALLED=$(dpkg-query -f '${Version}' -W ${DEB_NAME})   # 2.22.0

[[ ${VERSION_LATEST} == ${VERSION_INSTALLED} ]] && exit 0
curl -Lo /tmp/${DEB} ${LATEST_DOWNLOAD_URL}
sudo apt install -y /tmp/${DEB}
## Doesn't work on ubuntu-22.04
##
# The following packages have unmet dependencies:
#  onefetch : Depends: libc6 (>= 2.39) but 2.35-0ubuntu3.8 is to be installed