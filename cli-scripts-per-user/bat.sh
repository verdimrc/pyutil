#!/bin/bash

# Constants
APP=bat
GH=sharkdp/bat

mkdir -p ~/.local/bin
cd ~/.local/bin

latest_download_url() {
  [[ -n "$GH_TOKEN" ]] && local CURL_OPTS=(-H "Authorization: Bearer $GH_TOKEN" ) || local CURL_OPTS=()
  curl --silent "${CURL_OPTS[@]}" "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
      grep "\"browser_download_url\": \"https.*\/bat-.*-$(uname -i)-.*-linux-musl.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}

LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${LATEST_DOWNLOAD_URL##*/}
curl -LO ${LATEST_DOWNLOAD_URL}

# Go tarball has no root, so we need to create one
DIR=${TARBALL%.tar.gz}
tar -xzf $TARBALL ${DIR}/${APP} && rm $TARBALL
[[ -L ${APP} ]] && rm ${APP}
ln -s ${DIR}/${APP} ${APP} || true
