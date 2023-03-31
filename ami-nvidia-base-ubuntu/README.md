# Prep a base AMI for pre-built PyTorch <!-- omit in toc -->

This is for alinux2 (kernel 5.10) AMI.

Based on <https://github.com/aws-samples/aws-efa-nccl-baseami-pipeline/blob/master/nvidia-efa-ami_base/nvidia-efa-ml-ubuntu2204.yml>.

## Usage

Run these commands on the bash shell:

```bash
SRC_PREFIX=https://raw.githubusercontent.com/verdimrc/pyutil/master/ami-nvidia-base-ubuntu

declare -a SCRIPTS=(
    01.sh
    02.sh
)

mkdir -p ~/ami-nvidia-base-ubuntu/
cd ~/ami-nvidia-base-ubuntu/
curl $CURL_OPTS -O $SRC_PREFIX/{$(echo "${SCRIPTS[@]}" | tr ' ' ',')}
chmod ugo+x ${SCRIPTS[@]}

./01.sh
<<< Let the instance reboot, then reconnect. >>>
```

After reconnect, run these commands on the bash shell:

```bash
cd ~/ami-nvidia-base-ubuntu
./02.sh
./03.sh
#./03.sh nvvp  # To install just the NSight
```

Install Nice DCV:

```bash
# WARNING: NOT WORKING YET!!!
cd ~/ami-nvidia-base-ubuntu
curl -OL https://raw.githubusercontent.com/verdimrc/pyutil/master/ami-nvidia-base-ubuntu/install-dcv.sh
chmod ugo+x install-dcv.sh
./install-dcv.sh
# Then, follow the on-screen instructions.
```
