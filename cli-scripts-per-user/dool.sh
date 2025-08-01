#!/bin/bash

mkdir -p ~/.local/bin
mkdir $HOME/src
cd $HOME/src
git clone https://github.com/scottchiefbaker/dool
ln -s ~/src/dool/dool ~/.local/bin/dool
