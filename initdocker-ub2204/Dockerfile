# This Dockerfile is just an example. Review & update as needed.

FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y curl \
    && curl -v -sfL \
        -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" \
        https://raw.githubusercontent.com/verdimrc/pyutil/master/initdocker-ub2204/setup-my-docker.sh \
        | bash -s
