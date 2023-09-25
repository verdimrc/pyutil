# Usage <!-- omit in toc -->

Start an `Inf2` instance using the latest `Deep Learning AMI Neuron PyTorch 1.13 (Ubuntu 20.04) yyyymmdd`.

Then, connect to the instance, and on its terminal run these commands:

```bash
# This is needed when connecting via web-basd SSM connect
sudo -i -u ubuntu

mkdir -p ~/initdlami-ul2004-neuron-pt113
cd ~/initdlami-ul2004-neuron-pt113

# Download template config
curl -v \
    -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" \
    -sfLO \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/initdlami-ul2004-neuron-pt113/config.sh

# Edit the template config config.sh to suit your exact environment setup, e.g.:
# vi config.sh

# Download the run script
curl -v \
    -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" \
    -sfLO \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/initdlami-ul2004-neuron-pt113/run.sh
chmod 755 run.sh

# Apply the init logics
./run.sh 2>&1 | tee run.txt

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
mount | grep -e 'tcp' -e 'nfs4'
# Make sure you see the efs and fsx lustre mounts
```

If you reach this point, then all's good. You can then create an AMI out of this instance.
