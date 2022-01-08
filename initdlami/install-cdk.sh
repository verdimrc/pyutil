#!/bin/bash

################################################################################
# STEP-00: environment variables related to CDK
################################################################################
cat << 'EOF' >> ~/.bashrc

# NVM installation after this env. var. is effective should survive reboots.
export NVM_DIR=$HOME/.nvm
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"  # Loads nvm
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"  # Loads nvm bash_completion
EOF

# To speed-up shell initialization, locks to setup-time's EC2 instance.
CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity | grep Account | awk '{print $2}' | sed -e 's/"//g' -e 's/,//g')
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
CDK_DEFAULT_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]\$//'`"
cat << EOF >> ~/.bashrc

# To speed-up shell initialization, locks to setup-time's EC2 instance
export CDK_DEFAULT_ACCOUNT=$CDK_DEFAULT_ACCOUNT
export EC2_AVAIL_ZONE=$EC2_AVAIL_ZONE
export CDK_DEFAULT_REGION=$CDK_DEFAULT_REGION
EOF

# Still, we provide reference on how to regenerate the values.
cat << 'EOF' >> ~/.bashrc
################################################################################
# NOTE: this noticeably slows down shell initialization by another ~3 second.
# It's left as a reference in case you want to regenerate the above values.
################################################################################
#
# To bootstrap CDK to the account ID associated with the current credential.
# You may want to change to specific account ID instead.
#export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity | grep Account | awk '{print $2}' | sed -e 's/"//g' -e 's/,//g')
#
# To deploy a CDK stack to the region where the current EC2 or notebook instance is running.
# You may want to change to specific region instead.
#export EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
#export CDK_DEFAULT_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]\$//'`"
#
################################################################################
EOF


################################################################################
# STEP-01: helper functions to install cdk (only when not installed yet).
################################################################################
# Activate for the current shell.
export NVM_DIR=$HOME/.nvm
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"  # Loads nvm
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"  # Loads nvm bash_completion

detect_cmd() {
    "$@" &> /dev/null
    [[ $? == 0 ]] && echo "detected" || echo "not_detected"
}

mkdir -p $NVM_DIR

# Install nvm to NVM_DIR
if [[ $(detect_cmd nvm) == "not_detected" ]]; then
    echo "Installing nvm..."
    NVM_VERSION=$(curl -sL https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.name')
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"  # Loads nvm
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"  # Loads nvm bash_completion
fi
echo "Checking nvm:" `nvm --version`

# Install node.js (use lts version as-per CDK recommendation)
if [[ $(detect_cmd node -e "console.log('Running Node.js ' + process.version)") == "not_detected" ]]
then
    echo "Installing node.js and npm..."
    nvm install --lts
    nvm use --lts
    npm install -g npm
fi
node -e "console.log('Running Node.js ' + process.version)"
echo "Checking npm:" `npm -v`

# Install CDK
if [[ $(detect_cmd cdk --version) == "not_detected" ]]; then
    echo "Installing cdk..."
    npm install -g aws-cdk
fi

# Run once, and see if there's any warning re. incompatible node.js version
echo "CDK version:" $(cdk --version)
