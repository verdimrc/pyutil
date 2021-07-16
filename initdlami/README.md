# An Opinionated Customization on an alinux2 deep learning AMI Instance

Scripts to tweak on a fresh (i.e., newly created) EC2 instance running alinux
deep learning AMI, to make the notebook instance a little-bit more
ergonomics for prolonged usage.

- Jupyter Lab:
  * Reduce font size on Jupyter Lab
  * **\[Need sudo\]** Terminal defaults to `bash` shell, dark theme, and smaller font.
  * **\[Need sudo\]** Jupyter Lab to auto-scan `/home/ec2-user/SageMaker/envs/` for custom conda
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
  * git aliases: `git lol`, `git lola`, `git lolc`, and `git lolac`
  * New repo (i.e., `git init`) defaults to branch `main`
  * **\[Need sudo\]** `nbdime` for notebook-friendly diffs

- Terminal:
  * support color when ssh-ing using kitty terminal emulator.
  * `bash` shortcuts: `alt-.`, `alt-b`, `alt-d`, and `alt-f` work even when
    connecting from OSX.
  * **\[Need sudo\]** Install command lines: `fio`, `htop`, `tree`, `dos2unix`,
    `dstat`, `tig`, `ranger` (the CLI file explorer).
    + `ranger` is configured to use relative line numbers

- ipython run from Jupyter Lab's terminal:
  * shortcuts: `alt-.`, `alt-b`, `alt-d`, and `alt-f` work even when connecting
    from OSX.
  * recolor `o.__class__` from dark blue (nearly invisible on the dark theme) to
    a more sane color.

- Some customizations on `vim`: see `init-vim.sh`.

## Installation from github

This step needs to be done **once** on a newly *created* instance.

```bash
curl -sfL \
    https://raw.githubusercontent.com/verdimrc/pyutil/master/sagemaker-notebook/install-initsmnb.sh \
    | bash -s -- --git-user 'First Last' --git-email 'ab@email.abc'
```

## Installation from local source

You can also download this whole directory directly to `~/initdlami-src/`,
then invoke `install-initdlami.sh --from-local ...`.

## Usage: run on every EC2 instance only ONCE

Once installed, you should see file `/home/ec2-user/initdlami/setup-my-dlami.sh`.

Run this file **only once for an EC2 instance**.
