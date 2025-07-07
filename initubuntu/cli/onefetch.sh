#!/bin/bash

set -u

# https://github.com/o2sh/onefetch/wiki/Installation#ubuntu-ppa
sudo add-apt-repository ppa:o2sh/onefetch
sudo apt-get update
sudo apt-get install onefetch
