#!/bin/bash -x

# Environment variables to override:
# - REPO_NAME
# - S3_INPUT
# - S3_OUTPUT_PATH
# - GIT_CLONE (optional)
# - TARGET_DATA: 'train' or 'inference'

AWS_DEFAULT_REGION=$(curl --connect-timeout 1 -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account')
DEFAULT_BUCKET=s3://sagemaker-${AWS_DEFAULT_REGION}-${ACCOUNT}

REPO_NAME="${REPO_NAME:-my-github-repo}"
S3_INPUT="${S3_INPUT:-${DEFAULT_BUCKET}/my-default-input.tar.gz}"
S3_OUTPUT_PATH="${S3_OUTPUT_PATH:-${DEFAULT_BUCKET}/prep-output/my-default-output}"
GIT_CLONE="${GIT_CLONE:-0}"
PURPOSE="${PURPOSE:-train}"
INFERENCE_MODEL_NAME="${INFERENCE_MODEL_NAME:-BOOTSTRAP_NO_MODEL_NAME}"

declare -a PYARGS=()

parse_args() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        [[ $# -eq 1 ]] && max_shift=1 || max_shift=2
        case $key in
        -h|--help)
            echo "Usage: ${BASH_SOURCE[0]##*/} [options] -- [python script's options]"
            echo -e "  --repo-name <ARG>"
            echo -e "  --s3-input <ARG>"
            echo -e "  --s3-output <ARG>"
            echo -e "  --inference"
            echo -e "  --git-clone"
            exit 0
            ;;
        --repo-name)
            REPO_NAME="$2"
            shift $max_shift
            ;;
        --s3-input)
            S3_INPUT="$2"
            shift $max_shift
            ;;
        --s3-output)
            S3_OUTPUT_PATH="$2"
            shift $max_shift
            ;;
        --purpose)
            PURPOSE="$2"
            shift $max_shift
            ;;
        --inference-model-name)
            INFERENCE_MODEL_NAME="$2"
            shift $max_shift
            ;;
        --git-clone)
            GIT_CLONE=1
            shift
            ;;
        --)
            shift
            PYARGS+=( "$@" )
            break
            ;;
        *)
            echo 'Unknown option:' "$1"
            exit -1
        esac
    done

}

parse_args "$@"
echo REPO_NAME=${REPO_NAME}
echo S3_INPUT=${S3_INPUT}
echo S3_OUTPUT_PATH=${S3_OUTPUT_PATH}
echo GIT_CLONE=${GIT_CLONE}
echo PURPOSE=${PURPOSE}
echo PYARGS=${PYARGS}

# Update codebase, if requested.
if [[ $GIT_CLONE -eq '1' ]]; then
        REPO_URL=$(aws --region=ap-southeast-1 codecommit get-repository --repository-name amlsl-fpc-preproc \
                        | jq -r '.repositoryMetadata.cloneUrlHttp')

        echo 'Set Up AWS CLI Credential Helper for AWS CodeCommit HTTPS repositories'
        git config --global credential.helper '!aws codecommit credential-helper $@'
        git config --global credential.UseHttpPath true

        echo Cloning from REPO_URL=${REPO_URL}
        rm -fr ${REPO_NAME}
        git clone ${REPO_URL}
fi

# Download & extract input data
echo Downloading $S3_INPUT
mkdir -p /opt/ml/input/data/raw
mkdir -p /opt/ml/output/misc
COMPRESSION=${S3_INPUT##*.}
if [ "$COMPRESSION" == 'gz' ]; then
    aws s3 cp $S3_INPUT - | tar -xzf - -C /opt/ml/input/data/raw/
elif [ "$COMPRESSION" == 'zip' ]; then
    # unzip only works with real input file.
    aws s3 cp $S3_INPUT /tmp
    unzip -od /opt/ml/input/data/raw /tmp/${S3_INPUT##*/}
else
    echo 'Unknown compression:' $COMPRESSION >&2
fi

# Execute preproc script
echo Start execution: "${PYARGS[@]}"
export PATH=$(pwd):$PATH

INFERENCE_MODEL='S3__NONE'
if [ "$PURPOSE" == 'inference' ]; then
    # Re-write purpose to match ./prep.py
    ACTUAL_PURPOSE='infer_product'

    INFERENCE_MODEL=$(aws --region=ap-southeast-1 sagemaker describe-model --model-name $INFERENCE_MODEL_NAME \
                        | jq -r '.Containers[0].ModelDataUrl')
else
    ACTUAL_PURPOSE=$PURPOSE
fi

cd $REPO_NAME
PYARGS+=( --purpose $ACTUAL_PURPOSE --inference-model-s3 $INFERENCE_MODEL )
python ./prep.py "${PYARGS[@]}"
cd -

# Upload results to S3
echo Archive $PURPOSE output and upload to $S3_OUTPUT_PATH
if [ "$PURPOSE" == 'inference' ]; then
    aws s3 cp /opt/ml/output/product.csv $S3_OUTPUT_PATH/product.csv
    aws s3 cp /opt/ml/output/product.idx $S3_OUTPUT_PATH/product.idx
else
    for i in interactions-negative.csv interactions-positive.csv
    do
        aws s3 cp /opt/ml/output/$i $S3_OUTPUT_PATH/interactions/$i
    done
    tar -C /opt/ml/output/ -czvf - product.csv sales.csv | aws s3 cp - $S3_OUTPUT_PATH/tables.tar.gz
fi
tar -C /opt/ml/output/misc -czvf - . | aws s3 cp - $S3_OUTPUT_PATH/misc.tar.gz
