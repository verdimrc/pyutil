#!/bin/bash

set -euo pipefail

# Based on https://github.com/verdimrc/pyutil/blob/master/initdlami-ul2004-neuron-pt113/README.md

[[ $(whoami) == "ubuntu" ]] || { echo "Not ubuntu user. Exiting..." ; exit -1 }
mkdir -p ~/initdlami-ul2004-neuron-pt113
pushd ~/initdlami-ul2004-neuron-pt113
curl -v -sfLO \
    -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/initdlami-ul2004-neuron-pt113/run.sh
chmod 755 run.sh

echo "
##########################################################
# Next step, create your own config file:                #
#                                                        #
#     vi ~/initdlami-ul2004-neuron-pt113/config.sh       #
#     ...                                                #
#                                                        #
# Then, run below and follow the on-screen instructions: #
#                                                        #
#     ./run.sh                                           #
##########################################################
"
