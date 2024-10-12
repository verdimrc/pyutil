#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

# Constants
GH=dundee/gdu
TGZ_NAME=gdu_linux

latest_download_url() {
  local arch=$(uname -i) && [[ ${arch} == "x86_64" ]] && arch=amd64
  curl --silent "https://api.github.com/repos/${GH}/releases/latest"    |  # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/${TGZ_NAME}_${arch}.tgz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                           # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)  # https://github.com/.../v5.29.0/gdu_linux_amd64.tgz

VERSION_LATEST=${DOWNLOAD_URL##*/v} ; VERSION_LATEST=${VERSION_LATEST%%/*}   # 5.29.0
VERSION_INSTALLED=$(gdu --version | head -1 | awk '{print $2}' 2> /dev/null)
[[ ("v${VERSION_LATEST}" == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

TGZ=${DOWNLOAD_URL##*/}  # gdu_linux_amd64.tgz
BIN=${TGZ%.*}
curl -Lo /tmp/${TGZ} ${DOWNLOAD_URL}
sudo tar -xzf /tmp/${TGZ} --no-same-owner -C /usr/local/bin/ --transform="s/${BIN}/gdu/g" ${BIN}
