#!/bin/bash

IMG_DIR=train
JSON_DIR=train_annotation

echo "IMG_DIR=$IMG_DIR"
echo "JSON_DIR=$JSON_DIR"

rm $JSON_DIR/*.json
while read IMG; do
    JSON=${IMG%%.jpg}.json
    sed "s|REPLACE_ME|$IMG|" annotation-template.json > $JSON_DIR/$JSON
    echo Generated $JSON for $IMG
done < <(cd $IMG_DIR && ls -1 *.jpg)
