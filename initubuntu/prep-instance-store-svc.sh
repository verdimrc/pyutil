#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Newer DLAMI: Deep Learning Base GPU AMI (Ubuntu 20.04) 20230519) has prepared
# the instance NVMe via /lib/systemd/system/dlami-nvme.service.
if [[ $(mount | grep '\/opt\/dlami\/nvme') ]]; then
    systemctl stop dlami-nvme
    systemctl disable dlami-nvme
    # Removed /etc/systemd/system/multi-user.target.wants/dlami-nvme.service.
fi

# Backported from Deep Learning Base GPU AMI (Ubuntu 20.04) 20230519
cat << 'EOF' > /etc/systemd/system/prep-instance-store.service
[Unit]
Description=Mount Ephemeral NVME Storage to DLAMI
After=network.target

[Service]
Type=oneshot
ExecStart=/home/ubuntu/initubuntu/prep-instance-store.sh
TimeoutStartSec=300
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable prep-instance-store.service
systemctl restart prep-instance-store.service
systemctl status --no-pager prep-instance-store.service
