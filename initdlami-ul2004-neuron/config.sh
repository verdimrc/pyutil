#!/bin/bash

################################################################################
# 000: Settings -- feel free to change.
################################################################################
export GIT_USER=''
export GIT_EMAIL=''

# Comment or set to empty string to skip git clone
export GIT_REPO='codecommit::us-east-1://REPO_NAME'
export GIT_CHECKOUT_TO='main'

# EFS settings
export EFS_DNS="efs_file_system_dns_name"
export EFS_MOUNTDIR="/efs"

# FSx Lustre settings
export FSX_DNS="fsx_file_system_dns_name"
export FSX_MOUNTNAME="xxxx"
export FSX_MOUNTDIR="/fsx"
