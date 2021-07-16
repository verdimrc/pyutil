#!/bin/bash

# https://github.com/vercel/hyper/issues/2578#issuecomment-358897612
#
# Like terminado which jupyterlab leverages, hyper is also based on xterm.js.
# The workaround for hyper was found to also work on jupyterlab.

echo "Generating ~/.inputrc to fix a few bash shortcuts when browser runs on OSX..."
cat << EOF >> ~/.inputrc
# A few bash shortcuts when browser runs on OSX
"ƒ": forward-word
"∫": backward-word
"≥": yank-last-arg
"∂": kill-word
EOF

echo "Enabling keymap in ~/.bash_profile ..."
cat << EOF >> ~/.bash_profile

# Fix a few bash shortcuts when browser runs on OSX
bind -f ~/.inputrc
EOF

echo "Keymap set to deal with OSX quirks."
echo "To manually enforce keymap: bind -f ~/.inputrc"
