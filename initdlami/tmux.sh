#!/bin/bash
cd /tmp

get_latest_release() {
  curl --silent "https://api.github.com/repos/tmux/tmux/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

get_latest_download() {
  curl --silent "https://api.github.com/repos/tmux/tmux/releases/latest" | # Get latest release from GitHub api
    grep '"browser_download_url":' |                                # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}
curl -LO $(get_latest_download)

VERSION=$(get_latest_release)
sudo yum install -y libevent-devel ncurses-devel gcc make bison pkg-config
tar -xzf tmux-$VERSION.tar.gz
cd tmux-$VERSION/
./configure
make && sudo make install
make clean
