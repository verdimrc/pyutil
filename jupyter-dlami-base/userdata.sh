#!/bin/bash -xe

# Copy-paste this script to userdata section of your EC2 instance.
# Setup userdata to redirect stdout & stderr to file.
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2> /dev/console) 2>&1
echo Workdir: $(pwd)

# Global variables
EFS=fs-f7ccb7b6
S3_SRC_PREFIX=s3://vm-hello-world  # No trailing /
MINICONDA_SRC=s3://vm-hello-world/Miniconda3-20191202-Linux-x86_64.sh

# Setup EFS mount if defined
if [[ ! -z ${EFS} ]]; then
    yum install -y amazon-efs-utils
    EFS_OPTS='defaults,nofail,_netdev,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport'
    echo "${EFS}:/ /mnt/efs efs ${EFS_OPTS} 0 0" >> /etc/fstab
    mkdir /mnt/efs && mount /mnt/efs
fi

# Download scripts
declare -a FILES=(init.sh jupyter-lab-build.sh)
for i in "${FILES[@]}"; do
    aws s3 cp ${S3_SRC_PREFIX}/$i /home/ec2-user/
    chmod 755 /home/ec2-user/$i
    chown ec2-user:ec2-user /home/ec2-user/$i
done

# Run scripts.
# Use su rather than sudo to fix issue with conda<4.6.0 in dlami.
# The sudo version is commented for documentation, and should be preferred when
# dlami finally switches to conda>=4.6.0.
# - https://github.com/jupyter/docker-stacks/issues/678
# - https://github.com/conda/conda/issues/6569#issuecomment-353792497
#sudo -iu ec2-user ./init.sh ${MINICONDA_SRC}
su -l ec2-user -c ./init.sh ${MINICOND_SRC}

# Friendly message to ec2-user via a log file.
cat << EOF | sudo -iu ec2-user tee conda.log > /dev/null
Conda is ready. Check /var/log/user-data.log for details and optional next steps
(incl. sample conda create env. command).

Jupyter lab extensions may still be installed in background (may take 10+ minutes).
Please check jupyter-lab-ext.{log,INSTALLING,SUCCESS,FAILED}.
EOF
