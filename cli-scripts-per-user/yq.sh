#!/bin/bash

mkdir -p ~/.local/bin/ /tmp/${USER}
cd ~/.local/bin/

: "${FORCE_INSTALL:=0}"

# Constants
APP=yq
GH=mikefarah/yq

latest_download_url() {
  [[ -n "$GH_TOKEN" ]] && local CURL_OPTS=(-H "Authorization: Bearer $GH_TOKEN" ) || local CURL_OPTS=()
  curl --silent "${CURL_OPTS[@]}" "https://api.github.com/repos/${GH}/releases/latest"  |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/yq_linux_amd64.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}

DOWNLOAD_URL=$(latest_download_url)     # https://github.com/mikefarah/.../v4.44.3/yq_linux_amd64.tar.gz

VERSION_LATEST=${DOWNLOAD_URL%%/yq_linux*.tar.gz} ; VERSION_LATEST=${VERSION_LATEST##*/}    # v4.44.3
VERSION_INSTALLED=$(yq --version | cut -d' ' -f4)
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

TGZ=${DOWNLOAD_URL##*/}
curl -Lo /tmp/${USER}/${TGZ} ${DOWNLOAD_URL}
tar -xzf /tmp/${USER}/${TGZ} --no-same-owner -C /tmp/${USER} ./yq_linux_amd64 yq.1
mv /tmp/${USER}/${TGZ%%.*} ~/.local/bin/yq   # /tmp/${USER}/yq_linux_amd64 => ~/.local/bin/yq
mkdir -p ~/.local/share/man/man1/
mv /tmp/${USER}/yq.1 ~/.local/share/man/man1/
