#!/bin/bash -xe

# Copy-paste this script to userdata section of your EC2 instance (alinux2 or derivative).
# Setup userdata to redirect stdout & stderr to file.
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2> /dev/console) 2>&1
echo Workdir: $(pwd)

yum install -y tmux htop tree
yum update -y amazon-ssm-agent

cat << EOF > /usr/lib/systemd/system/tmux-ec2-user.service
[Unit]
Description=tmux run as ec2-user

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/tmux new-session -d
#ExecStop=/usr/bin/tmux kill-server
KillMode=none
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target
EOF

systemctl enable tmux-ec2-user
systemctl start tmux-ec2-user
