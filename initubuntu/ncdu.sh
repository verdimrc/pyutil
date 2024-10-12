#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

# Constants
SITE=https://dev.yorhel.nl

latest_download_url() {
  local path=$(curl --silent ${SITE}/ncdu | grep -m 1 -o "/download/ncdu-[0-9.]*-linux-$(uname -i).tar.gz")
  echo -n "${SITE}${path}"
}

DOWNLOAD_URL=$(latest_download_url)  # https://dev.yorhel.nl/download/ncdu-2.6-linux-x86_64.tar.gz

VERSION_LATEST=${DOWNLOAD_URL##*/ncdu-} ; VERSION_LATEST=${VERSION_LATEST%%-*}  # 2.6
VERSION_INSTALLED=$(ncdu --version | cut -d' ' -f2 2> /dev/null)
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

TGZ=${DOWNLOAD_URL##*/}  # ncdu-2.6-linux-x86_64.tar.gz
curl -Lo /tmp/${TGZ} ${DOWNLOAD_URL}
sudo tar -xzf /tmp/${TGZ} --no-same-owner -C /usr/local/bin/ ncdu