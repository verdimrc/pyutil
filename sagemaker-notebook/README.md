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

This step needs to be done **once** on a newly *created* notebook instance.

Go to the Jupyter Lab on your SageMaker notebook instance. Open a terminal,
then run this command:

```bash
curl -sfL \
    https://raw.githubusercontent.com/verdimrc/pyutil/initsmnb-installer/sagemaker-notebook/install-initsmnb.sh \
    | bash -s -- 'Git-committer-firstname Lastname' 'git-committer@email.abc'
```

Change the git committer's name and email to your liking.
- To use default name (i.e., `ec2-user`), specify `''` for the commiter name.
- Likewise, specify `''` to keep the commiter email to SageMaker notebook's default.


## Usage
Once installed, you should see file `/home/ec2-user/SageMaker/initsmnb/setup-my-sagemaker.sh`.

Run this file to apply the changes to the current session, and follow the
instruction to restart the Jupyter server (and after that, do remember to reload
your browser tab).

Due to how SageMaker notebook works, please re-run `setup-my-sagemaker.sh` on a
newly *started* or *restarted* instance. You may even consider to automate this
step using SageMaker lifecycle config.
