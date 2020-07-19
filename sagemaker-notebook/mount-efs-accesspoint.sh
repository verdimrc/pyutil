#!/bin/bash

# Prerequisite:
# - EFS access point has been configured.
# - Notebook has to be in the same VPC as EFS. EFS access point will handle the owner/permission.

echo Mount EFS access point onto Sagemaker home directory
echo Usage: ${BASH_SOURCE[0]} "efs_file_id" "efs_accesspoint_id" "full_mount_path"
echo

EFS_FILE_ID=$1
EFS_ACCESSPOINT_ID=$2
MOUNT_POINT=$3

if [[ ${EFS_FILE_ID} == "" ]] || [[ ${EFS_ACCESSPOINT_ID} == "" ]] || [[ ${MOUNT_POINT} == "" ]];then
    echo "Error: Missing arguments"
    exit 1
fi

echo "EFS_FILE_ID:" ${EFS_FILE_ID}
echo "EFS_ACCESSPOINT_ID:" ${EFS_ACCESSPOINT_ID}
echo "MOUNT_POINT:" ${MOUNT_POINT}

mkdir -p ${MOUNT_POINT}

# Install efs utitlity
sudo yum install -y amazon-efs-utils

sudo mount -t efs -o tls,accesspoint=${EFS_ACCESSPOINT_ID} ${EFS_FILE_ID}: ${MOUNT_POINT} --verbose

echo "Done"