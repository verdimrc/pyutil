#!/bin/bash
sudo yum install -y tree htop fio dstat dos2unix tig
sudo yum clean all

sudo /usr/bin/pip3 install --no-cache-dir nbdime ranger-fm
mkdir -p ~/.config/ranger/
echo set line_numbers relative >> ~/.config/ranger/rc.conf
