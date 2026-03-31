#!/bin/bash

mkdir -p /tmp/${USER}
cd /tmp/${USER}

get_latest_release() {
    local s="$1"        # https://xxx/xxx/xxx/tmux-3.6a.tar.gz
    s="${s#*tmux-}"     # 3.6a.tar.gz
    s="${s%.tar.gz}"    # 3.6a
    echo "$s"
}

get_latest_download() {
  [[ -n "$GH_TOKEN" ]] && local CURL_OPTS=(-H "Authorization: Bearer $GH_TOKEN" ) || local CURL_OPTS=()
  curl --silent "${CURL_OPTS[@]}" "https://api.github.com/repos/tmux/tmux/releases/latest" | # Get latest release from GitHub api
    grep '"browser_download_url":' |                                # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}
DOWNLOAD_URL=$(get_latest_download)
curl -LO $DOWNLOAD_URL
VERSION=$(get_latest_release $DOWNLOAD_URL)

sudo -n true 2>/dev/null && CAN_SUDO=1 || CAN_SUDO=0
[[ $CAN_SUDO -eq 1 ]] && sudo apt install -y libevent-dev ncurses-dev gcc make bison pkg-config
tar -xzf tmux-$VERSION.tar.gz
cd tmux-$VERSION/

set -exuo pipefail
./configure &> ../tmux-00-configure.txt
make &> ../tmux-01-make.txt
if [[ $CAN_SUDO -eq 1 ]]; then
   sudo make install &> ../tmux-02-make-install.txt
else
   mkdir -p ~/.local/bin
   cp tmux ~/.local/bin
fi
make clean &> ../tmux-03-make-clean.txt
cd ..
rm tmux-$VERSION.tar.gz
rm -fr tmux-$VERSION/
