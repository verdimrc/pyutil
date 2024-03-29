#!/bin/bash

# Recognize kitty
sudo sed -i 's/\(^TERM st-256color$\)/\1\nTERM xterm-kitty/' /etc/DIR_COLORS.256color

# Pre-emptively get kitty's termcap, to avoid the need to 'kitty +kitten ssh <...>'.
mkdir -p ~/.terminfo/{78,x}/
curl -L https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo > ~/.terminfo/kitty.terminfo
curl -L https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/x/xterm-kitty > ~/.terminfo/x/xterm-kitty
ln -s ../x/xterm-kitty ~/.terminfo/78/

# Tone-down directory colors to lighter blue
TAB=$(printf '\t')
sudo sed -i "s/^DIR 38;5;27\(${TAB}\)/DIR 38;5;39\1/" /etc/DIR_COLORS.256color

# Make sudo to inherit term and colors
echo 'Defaults    env_keep += "TERM TERMINFO"' | sudo tee /etc/sudoers.d/95-term
sudo chmod o-r /etc/sudoers.d/95-term
sudo mkdir -p /root/.terminfo/x/
sudo /bin/bash -c '
if [[ ! -f ~/.terminfo/x/xterm-kitty ]]; then
    mkdir -p ~/.terminfo/x/
    ln -s ~ec2-user/.terminfo/x/xterm-kitty ~/.terminfo/x/
fi
'
