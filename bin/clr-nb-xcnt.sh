#!/usr/bin/env bash

sed -i 's/\(^  *"execution_count": \)[0-9][0-9]*,$/\1null,/g' "$1"
