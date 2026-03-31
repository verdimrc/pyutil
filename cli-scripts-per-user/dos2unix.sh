#!/bin/bash

mkdir -p /tmp/${USER}
cd /tmp/${USER}

DOWNLOAD_URL=$(curl -s https://sourceforge.net/projects/dos2unix/best_release.json | jq -r '.platform_releases.linux.url')
curl -LO $DOWNLOAD_URL

get_latest_release() {
    local s="$1"         # dos2unix-7.5.4.tar.gz
    s="${s#*dos2unix-}"   # 7.5.4.tar.gz
    s="${s%.tar.gz*}"     # 7.5.4
    echo "$s"
}

VERSION=$(get_latest_release $DOWNLOAD_URL)

sudo -n true 2>/dev/null && CAN_SUDO=1 || CAN_SUDO=0
[[ $CAN_SUDO -eq 1 ]] && echo HAHA: not implemented: sudo apt install -y ...
tar -xzf dos2unix-$VERSION.tar.gz
cd dos2unix-$VERSION/

set -exuo pipefail
make &> ../dos2unix-00-make.txt
if [[ $CAN_SUDO -eq 1 ]]; then
   sudo make install &> ../tmux-02-make-install.txt
else
   mkdir -p ~/.local/bin
   cp -t ~/.local/bin/ --no-dereference dos2unix mac2unix unix2dos unix2mac
fi
make clean &> ../dos2unix-01-make-clean.txt
cd ..
rm dos2unix-$VERSION.tar.gz
rm -fr dos2unix-$VERSION/
