#!/bin/bash

# See: https://stackoverflow.com/a/55609950
git ls-tree -r --name-only HEAD | while read filename; do
  unixtime=$(git log -1 --format="%at" -- "${filename}")
  touchtime=$(date -d @$unixtime +'%Y%m%d%H%M.%S')
  touch -t ${touchtime} "${filename}"
done
