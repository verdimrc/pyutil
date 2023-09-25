# Usage <!-- omit in toc -->

## Pre-requisites

Start an `Inf2` instance using the latest `Deep Learning AMI Neuron PyTorch 1.13 (Ubuntu 20.04) yyyymmdd`.

## Customizing Instance

Once the instance is ready, connect to it. On its terminal, run these commands:

```bash
# This is needed when connecting via web-basd SSM connect
sudo -i -u ubuntu

curl -v -sfL \
    -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/initdlami-ul2004-neuron-pt113/bootstrap-initneuron.sh \
    | bash -s

# Then, follow the OSD instructions.
```

At some point, you'll be asked to reboot. After reboot, reconnect to the instance

```bash
# This is needed when connecting via web-basd SSM connect
sudo -i -u ubuntu

# Verify /fsx and /efs
ls -al /fsx/ /efs/
mount | egrep 'tcp|nfs4'
# Make sure you see the efs and fsx lustre mounts
```

If you reach this point, then all's good. You can then create an AMI out of this instance.
