[[ -e ~/.marcverd.inputrc ]] || \
cat << 'EOF' > ~/.marcverd.inputrc
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

bind -f ~/.marcverd.inputrc

# Requires git>=x.x.x
export GIT_CONFIG_GLOBAL=~/.marcverd.gitconfig

export GIT_AUTHOR_NAME='Firstname Lastname'
export GIT_AUTHOR_EMAIL='first.last@domain.com'
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME
export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
export PATH=~/.local/bin:$PATH

source ~/.marcverd.bashrc
