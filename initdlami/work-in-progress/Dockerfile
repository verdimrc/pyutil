FROM ubuntu:22.04

ARG EFA_PKG=aws-efa-installer-latest.tar.gz
RUN echo 'kernel.yama.ptrace_scope = 0' |  tee -a /etc/sysctl.conf \
    && sysctl -p && apt update && apt install -y wget \
    && cd /tmp && \
    wget -O /tmp/aws-efa-installer.tar.gz https://efa-installer.amazonaws.com/$EFA_PKG \
    && tar -xf /tmp/aws-efa-installer.tar.gz -C /tmp \
    && cd /tmp/aws-efa-installer \
    && ./efa_installer.sh -y --debug --skip-kmod --skip-limit-conf --no-verify

RUN /opt/amazon/efa/bin/fi_info --version
ENV PATH=/opt/amazon/efa/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/amazon/efa/lib:$LD_LIBRARY_PATH
