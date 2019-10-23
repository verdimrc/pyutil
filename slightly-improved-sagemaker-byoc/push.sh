#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

ARCH=cpu
image=''
parse_args() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -h|--help)
            usage "Usage: ${BASH_SOURCE[0]} [-g|--gpu] IMAGE_NAME"
            exit 0
            ;;
        -g|--gpu)
            ARCH=gpu
            shift
            ;;
        *)
            # The argument to this script is the image name. This will be used as the image on the local
            # machine and combined with the account and region to form the repository name for ECR.
            #
            # This script only needs one image name, so the last one wins.
            image=$1
            shift
            ;;
        esac
    done

    if [ "$image" == "" ]
    then
        echo "Usage: ${BASH_SOURCE[0]} [-g|--gpu] IMAGE_NAME"
        exit 1
    fi

}

# Parse CLI arguments
parse_args "$@"

# Tasks this script will perform: build, push, or both.
# Detection mechanism:
# - if invoked as *build*.sh, then include "build" task
# - if invoked as *push*.sh, then include "push" task
BUILD=0
PUSH=0
echo Script invoked as $(basename ${BASH_SOURCE[0]})
if [[ $(basename ${BASH_SOURCE[0]}) =~ .*build.* ]]; then
    BUILD=1
fi
if [[ $(basename ${BASH_SOURCE[0]}) =~ .*push.* ]]; then
    PUSH=1
fi
echo -n 'Tasks:'
[[ $BUILD -eq 1 ]] && echo -n " build-${ARCH}"
[[ $PUSH -eq 1 ]] && echo -n " push"
echo

# Make sure both these scripts are executable. If you version these scripts,
# it's best to (set exec + commit) before running this script, to avoid
# introducing unstaged changes to git repo.
chmod +x wide_and_deep/train
chmod +x wide_and_deep/serve

# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

# Get the region defined in the current configuration
region=$(aws configure get region)

# Default region if none configured
region=${region:-ap-southeast-1}    # Default region if none configured

# If anything failed up to this point, exit immediately.
[ $? -ne 0 ] && exit 255

fullname="${account}.dkr.ecr.${region}.amazonaws.com/${image}:latest"

if [[ $BUILD -eq 1 ]]; then
	# Build the docker image locally with the image name and then push it to ECR
	# with the full name.

    # AWS account who owns the base container
    BASE_ACC=520713654638       # To base on a SageMaker container
    #BASE_ACC=763104351884       # To base on a DL container

    # Authenticate to access base container
	$(aws ecr get-login --no-include-email --region ${region} --no-include-email --registry-ids ${BASE_ACC})

    # Build the local container image
	docker build  -f Dockerfile.${ARCH} -t ${image} .

	# Tag the local container image
	docker tag ${image} ${fullname}
fi

if [[ $PUSH -eq 1 ]]; then
	# Authenticate to your ECR: get the login command from ECR and execute it directly
	$(aws ecr get-login --region ${region} --no-include-email)

	# If the repository doesn't exist in your ECR, create it.
	aws --region ${region} ecr describe-repositories --repository-names "${image}" > /dev/null 2>&1
	[ $? -ne 0 ] && aws --region ${region} ecr create-repository --repository-name "${image}" > /dev/null

    # Push local container image to your ECR repository.
	docker push ${fullname}
fi
