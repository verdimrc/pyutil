# An Opinionated Customization on SageMaker Notebook Instance

Scripts to re-run common tasks on a fresh (i.e., newly created or rebooted)
SageMaker notebook instance:

- Jupyter Lab:
  * Terminal defaults to `bash` shell, dark theme, and smaller font.
  * Reduce font size on Jupyter Lab
  * Jupyter Lab to auto-scan `/home/ec2-user/SageMaker/envs/` for custom conda
    environments. Note that after you create a new custom conda environment on
    `/home/ec2-user/SageMaker/envs/`, you may need to
    [restart JupyterLab](#appendix-restart-jupyterlab) before you can see the
    environment listed as one of the kernels.

    <details><summary style="font-size:60%">Implementation notes</summary>

    > An older implementation was to trigger `ipykernel install` (refer to the
    > [deprecated script](https://github.com/verdimrc/pyutil/blob/master/sagemaker-notebook/deprecated/reinstall-ipykernel.sh)).
    > However, recently SageMaker notebook updated to conda-4.8.x, and the
    > deprecated step may be dangerous because while the notebook Python cells
    > correctly use your custom environment, but the `!` and `%%bash` directives
    > still use the `JupyterSystemEnv` environment.
    </details>

- Git:
  * Optionally change committer's name and email, which defaults to `ec2-user`
  * `git lol` and `git lola` aliases
- Terminal:
  * `bash` shortcuts: `alt-.`, `alt-b`, `alt-d`, and `alt-f` work even when
    connecting from OSX.
  * Install `htop` and `tree` commands.
- ipython run from Jupyter Lab's terminal:
  * shortcuts: `alt-.`, `alt-b`, `alt-d`, and `alt-f` work even when connecting
    from OSX.
  * recolor o.__class__ from dark blue (nearly invisible) to a more sane color.
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
    https://raw.githubusercontent.com/verdimrc/pyutil/master/sagemaker-notebook/install-initsmnb.sh \
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

## Appendix: Restart JupyterLab

On the Jupyter Lab's terminal, run this command:

```bash
sudo initctl restart jupyter-server --no-wait
```

Then, reload your browser tab.
