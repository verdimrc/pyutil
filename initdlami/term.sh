#!/bin/bash
sudo sed -i 's/\(^TERM st-256color$\)/\1\nTERM xterm-kitty/' /etc/DIR_COLORS.256color
TAB=$(printf '\t')
sudo sed -i "s/^DIR 38;5;27\(${TAB}\)/DIR 38;5;39\1/" /etc/DIR_COLORS.256color
