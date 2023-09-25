# Usage <!-- omit in toc -->

Start an `Inf2` instance using the latest `Deep Learning AMI Neuron PyTorch 1.13 (Ubuntu 20.04) yyyymmdd`.

Then, connect to the instance, and on its terminal run these commands:

```bash
# This is needed when connecting via web-basd SSM connect
sudo -i -u ubuntu

curl -v \
    -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" \
    -sfL \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/initdlami-ul2004-neuron-pt113/bootstrap-initneuron.sh \
    | bash -s

# Edit the template config config.sh to suit your exact environment setup, e.g.:
# vi ~/initdlami-ul2004-neuron-pt113/config.sh

# Apply the init logics
~/initdlami-ul2004-neuron-pt113/run.sh 2>&1 | tee run-initneuron.txt

# When asked to reboot, reboot...
sudo reboot
```

After reboot, reconnect to the instance

```bash
# This is needed when connecting via web-basd SSM connect
sudo -i -u ubuntu

# Verify /fsx and /efs
ls -al /fsx/
ls -al /efs/
mount | egrep 'tcp|nfs4'
# Make sure you see the efs and fsx lustre mounts
```

If you reach this point, then all's good. You can then create an AMI out of this instance.
