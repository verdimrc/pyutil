#!/usr/bin/env bash

# This script wraps github.com/remind101/assume-role to set the AWS_PROFILE
# environment variable, instead of ASSUMED_ROLE, so that subsequent aws cli
# defaults to the region override of the assumed profile.

while read LINE; do
    if [[ $LINE =~ ^"export ASSUMED_ROLE="* ]]; then
        echo $LINE | sed 's/ASSUMED_ROLE/AWS_PROFILE/'
    else
        echo $LINE
    fi
done < <(assume-role "$@")
