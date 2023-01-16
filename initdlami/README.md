# An Opinionated Customization on an alinux2 deep learning AMI Instance

Scripts to tweak on a fresh (i.e., newly created) EC2 instance running alinux2

## Installation from github

```bash
curl -v -H "Cache-Control: no-cache" -sfL \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/initdlami/install-initdlami.sh \
    | bash -s -- --git-user 'First Last' --git-email 'ab@email.abc'
```

## Installation from local source

You can also download this whole directory directly to `~/initdlami-src/`,
then invoke `install-initdlami.sh --from-local ...`.

## Usage: run on every EC2 instance only ONCE

Once installed, you should see file `/home/ec2-user/initdlami/setup-my-dlami.sh`.

Run this file **only once for an EC2 instance**.

Tips when installing from the session manager connect (EC2 console):

when whoami shows ssm-user

```bash
sudo su -l ec2-user
cd ; screen -dm bash -c /home/ec2-user/initdlami/setup-my-dlami.sh

# ctrl-a-d
# screen -ls
# screen -x
```
