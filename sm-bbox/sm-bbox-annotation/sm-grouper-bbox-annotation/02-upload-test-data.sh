#!/bin/bash

S3_PREFIX='s3://bucket/grouper'
for i in train train_annotation; do
    aws --profile=default s3 sync $i $S3_PREFIX/$i --storage-class ONEZONE_IA --exclude '*' --include '*.jpg' --include '*.json'
done
