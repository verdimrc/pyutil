#!/bin/bash

# Pre-emptively get kitty's termcap, to avoid the need to 'kitty +kitten ssh <...>'.
mkdir -p ~/.terminfo/{78,x}/
curl -L https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo > ~/.terminfo/kitty.terminfo
curl -L https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/x/xterm-kitty > ~/.terminfo/x/xterm-kitty
ln -s ../x/xterm-kitty ~/.terminfo/78/

# Make sudo to inherit term and colors
echo 'Defaults    env_keep += "TERM TERMINFO"' | sudo tee /etc/sudoers.d/95-term
sudo chmod o-r /etc/sudoers.d/95-term
sudo mkdir -p /root/.terminfo/x/
sudo /bin/bash -c '
if [[ ! -f ~/.terminfo/x/xterm-kitty ]]; then
    mkdir -p ~/.terminfo/x/
    ln -s ~ubuntu/.terminfo/x/xterm-kitty ~/.terminfo/x/
fi
'
