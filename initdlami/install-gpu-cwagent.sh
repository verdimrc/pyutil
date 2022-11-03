#!/bin/bash

cat << 'EOF'
Setting-up GPU metrics monitoring through the CloudWatch Agent.
Based on https://aws.amazon.com/blogs/compute/capturing-gpu-telemetry-on-the-amazon-ec2-accelerated-computing-instances/
EOF


################################################################################
# Sanity checks
################################################################################
if [[ "$EUID" -ne 0 ]]; then
    echo "${BASH_SOURCE[0]} not run as root. Refuse to continue."
    exit -1
fi

nvidia-smi &> /dev/null
if [[ $? -ne 0 ]]; then
    echo "Failed to detect GPU card. Ignore CloudWatch Agent for GPU metrics."
    exit -2
fi


################################################################################
# May uncomment this stanza during dev/test
################################################################################
# rm /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
#     /etc/systemd/system/aws-hw-monitor.service \
#     /opt/aws/cloudwatch/aws-cloudwatch-wrapper.sh \
#     /opt/aws/aws-hwaccel-event-parser.py
# sudo systemctl daemon-reload


################################################################################
# Here we go
################################################################################
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "run_as_user": "root"
    },
    "metrics": {
        "append_dimensions": {
            "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
            "ImageId": "${aws:ImageId}",
            "InstanceId": "${aws:InstanceId}",
            "InstanceType": "${aws:InstanceType}"
        },
        "aggregation_dimensions": [ [ "InstanceId" ] ],
        "metrics_collected": {
            "mem": {
                "measurement": [
                    "mem_total",
                    "mem_free",
                    "mem_buffered",
                    "mem_cached",
                    "mem_used",
                    "mem_used_percent",
                    "mem_available",
                    "mem_available_percent"
                ]
            },
            "nvidia_gpu": {
                "measurement": [
                    "utilization_gpu",
                    "utilization_memory",
                    "memory_total",
                    "memory_used",
                    "memory_free",
                    "clocks_current_graphics",
                    "clocks_current_sm",
                    "clocks_current_memory"
                ]
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/gpuevent.log",
                        "log_group_name": "/ec2/accelerated/accel-event-log",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Alternatively: download the .go version
curl -L \
    https://raw.githubusercontent.com/aws-samples/aws-efa-nccl-baseami-pipeline/master/nvidia-efa-ami_base/cloudwatch/nvidia/aws-hwaccel-event-parser.py \
    | tee /opt/aws/aws-hwaccel-event-parser.py > /dev/null

cat << 'EOF' > /etc/systemd/system/aws-hw-monitor.service
[Unit]
Description=HW Error Monitor
Before=amazon-cloudwatch-agent.service
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=/opt/aws/cloudwatch/aws-cloudwatch-wrapper.sh
RemainAfterExit=1
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /opt/aws/cloudwatch/
cat << 'EOF' > /opt/aws/cloudwatch/aws-cloudwatch-wrapper.sh
#!/bin/bash
python3 /opt/aws/aws-hwaccel-event-parser.py &
EOF
chmod 755 /opt/aws/cloudwatch/aws-cloudwatch-wrapper.sh


################################################################################
# Enable all agent services
################################################################################
for i in amazon-cloudwatch-agent.service aws-hw-monitor.service; do
    systemctl enable $i --now
    echo && systemctl status $i
done
