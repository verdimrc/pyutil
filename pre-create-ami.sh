#!/bin/bash

[[ ~/.ssh/authorized_keys ]] && rm ~/.ssh/authorized_keys

sed -i \
    -e 's/^\(export AWS_ACCOUNT=.*\)$/#\1/' \
    -e 's/^\(export EC2_AVAIL_ZONE=.*\)$/#\1/' \
    -e 's/^\(export CDK_DEFAULT_ACCOUNT=.*\)$/#\1/' \
    -e 's/^\(export CDK_DEFAULT_REGION=.*\)$/#\1/' \
    ~/.bashrc
