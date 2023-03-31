#!/bin/bash

# Based of https://github.com/aws-samples/aws-efa-nccl-baseami-pipeline

wget -O /tmp/awscli2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
sudo bash -c "
cd /tmp
unzip awscli2.zip
./aws/install
/usr/local/bin/aws --version
cd /tmp
rm awscli2.zip
rm -fr aws/
"

[[ $(which aws) != "/usr/local/bin/aws" ]] && echo "WARNING: not using /usr/local/bin/aws"
aws --version

aws configure set default.s3.max_concurrent_requests 100
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
aws configure set default.cli_auto_prompt on-partial
