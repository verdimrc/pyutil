#!/bin/bash

# https://github.com/vercel/hyper/issues/2578#issuecomment-358897612
#
# Like terminado which jupyterlab leverages, hyper is also based on xterm.js.
# The workaround for hyper was found to also work on jupyterlab.

echo "Generating ~/.inputrc to fix a few bash shortcuts when browser runs on OSX..."
cat << 'EOF' >> ~/.inputrc
# A few bash shortcuts when ssh-ing from OSX
"ƒ": forward-word    # alt-f
"∫": backward-word   # alt-b
"≥": yank-last-arg   # alt-.
"∂": kill-word       # alt-d

";3D": backward-word  # alt-left
";3C": forward-word   # alt-right

"\e[1;3D": backward-word ### Alt left
"\e[1;3C": forward-word ### Alt right
EOF

echo "Enabling keymap in ~/.profile ..."
cat << EOF >> ~/.profile

# Fix a few bash shortcuts when browser runs on OSX
bind -f ~/.inputrc
EOF

echo "Keymap set to deal with OSX quirks."
echo "To manually enforce keymap: bind -f ~/.inputrc"
