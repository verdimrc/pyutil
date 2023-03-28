#!/bin/bash

# To speed-up shell initialization, locks to setup-time's EC2 instance.
ACCOUNT=$(aws sts get-caller-identity | grep Account | awk '{print $2}' | sed -e 's/"//g' -e 's/,//g')
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]\$//'`"

# Set aws config
aws configure set default.region $REGION

# Add environment variables
cat << EOF >> ~/.bashrc

# Non-standard environment variables
export AWS_ACCOUNT=$ACCOUNT
export EC2_AVAIL_ZONE=$EC2_AVAIL_ZONE

# AWS CLI's environment variables
# Fallback to ~/.aws/config
#export AWS_DEFAULT_REGION=$REGION
#export AWS_REGION=$REGION

# CDK's environment variables
export CDK_DEFAULT_ACCOUNT=$ACCOUNT
export CDK_DEFAULT_REGION=$REGION
EOF

# Provide reference on how to regenerate the values.
cat << 'EOF' >> ~/.bashrc

################################################################################
# NOTE: this noticeably slows down shell initialization by another ~3 second.
# It's left as a reference in case you want to regenerate the above values.
################################################################################
#AWS_ACCOUNT=$(aws sts get-caller-identity | grep Account | awk '{print $2}' | sed -e 's/"//g' -e 's/,//g')
#EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
#AWS_DEFAULT_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]\$//'`"
################################################################################
EOF
