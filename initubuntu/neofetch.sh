#!/bin/bash

set -u

: "${FORCE_INSTALL:=0}"

VERSION_INSTALLED=$(sha1sum $(which neofetch || echo /dev/null) | cut -d' ' -f1)
VERSION_LATEST='3296e79594f7febb0a777430ce548ccaa51c4152'  # Master, archieved. Commit ccd5d9f.
[[ (${VERSION_LATEST} == ${VERSION_INSTALLED}) && (${FORCE_INSTALL} != 1) ]] && exit 0

sudo curl -Lo /usr/local/bin/neofetch https://raw.githubusercontent.com/dylanaraps/neofetch/refs/heads/master/neofetch
sudo chmod 755 /usr/local/bin/neofetch