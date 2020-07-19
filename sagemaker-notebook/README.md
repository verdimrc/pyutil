# An Opinionated Customization on SageMaker Notebook Instance

Scripts to re-run common tasks on a fresh (i.e., newly created or rebooted)
SageMaker notebook instance:

- Jupyter Lab:
  * Terminal defaults to `bash` shell, dark theme, and smaller font.
  * Reduce font size on Jupyter Lab
- Git:
  * Optionally change committer's name and email, which defaults to `ec2-user`
  * `git lol` and `git lola` aliases
- `bash` shortcuts: `alt-.`, `alt-b`, `alt-d`, and `alt-f` work even when
  connecting from OSX.
- Some customizations on `vim`:
  * Notably, change window navigation shortcuts from `ctrl-w-{h,j,k,l}` to
    `ctrl-{h,j,k,l}`.

    Otherwise, `ctrl-w` is used by most browsers on Linux (and Windows?) to
    close a browser tab, which renders windows navigation in `vim` unusable.

  * Other opinionated changes; see `init-vim.sh` in this repo, and the template
    `.vimrc` in [this repo](https://github.com/verdimrc/linuxcfg/blob/master/.vimrc).


## Installation

```bash
curl -sfL https://github.com/verdimrc/pyutil/blob/master/sagemaker-notebook/install-initsmnb.sh \
    | bash -s -- 'Git-committer-firstname Lastname' 'git-committer@email.abc'
```


## Usage
Once installed, you should see file `/home/ec2-user/SageMaker/initsmnb/setup-my-sagemaker.sh`.
Run this file to apply the changes to the current session.

Note that due to the way SageMaker notebook works, you should re-run
`setup-my-sagemaker.sh` after reboot. Alternatively, you can consider to create
lifecycle config to auto-run the script on notebook restart.
