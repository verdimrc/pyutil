# Usage <!-- omit in toc -->

Start an `Inf2` instance using the latest `Deep Learning AMI Neuron PyTorch 1.13 (Ubuntu 20.04) yyyymmdd`.

Then, go to the terminal (i.e., via web-based SSM connect) and run these commands:

```bash
# This is needed when connecting via web-basd SSM connect
sudo -i -u ubuntu

mkdir -p ~/initdlami-ul2004-neuron-pt113
cd ~/initdlami-ul2004-neuron-pt113

# Download template config
curl -LO https://raw.githubusercontent.com/verdimrc/pyutil/dlami-ul2004-neuron/initdlami-ul2004-neuron-pt113/config.sh

# Edit the template config config.sh to suit your exact environment setup, e.g.:
# vi config.sh

# Download the run script
curl -LO https://raw.githubusercontent.com/verdimrc/pyutil/dlami-ul2004-neuron/initdlami-ul2004-neuron-pt113/run.sh
chmod 755 run.sh

# Apply the init logics
./run.sh 2>&1 | tee run.txt
```
