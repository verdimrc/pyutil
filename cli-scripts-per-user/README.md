Recommended steps

```bash
# install to home dir, not requiring sudo.
./initdlami/bat.sh
./initubuntu/cli/deprecated/delta-tgz.sh
./initdlami-ub2004-gpu/yq.sh   
./cli-scripts-per-user/duf.sh
./cli-scripts-per-user/ripgrep.sh
./cli-scripts-per-user/dool.sh

# Do this after delta.
# Set GIT_* env var, so can write to .marcverd.gitconfig to avoid conflict with others when
# sharing the same linux username/account.
~/.marcverd.profile   
./initubuntu/adjust-git.sh 'Firstname lastname' name@email.com
```
