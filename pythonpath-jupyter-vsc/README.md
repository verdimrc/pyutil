# What this is about

A skeleton of project structure with sample Jupyter & Visual Studio Code configurations on setting `PYTHONPATH` to include custom directories.

- Visual Studio Code: see `.vscode/settings.json` and `.env`.

  For detail explanations (+other sample settings), see [this sample config](https://github.com/verdimrc/linuxcfg/tree/master/.vscode). Basically, with this config, VSC intellisense will be able to recognize custom modules located under `haha` and `hehe`. In addition, the terminals (be it the embedded or interactive) will also recognize those custom modules located under `haha` and `hehe`.

- Jupyter: see `test.ipynb` and `ipython_config.py`.

  Basically, with this config, when a notebook kernel is started, it'll automatically add add additional directories to the `PYTHONPATH`. The sample `test.ipynb` shows how it can import custom modules located under `haha` and `hehe`.

NOTE: if your notebooks is part of a git repo, then have a look at a more general `ipython_config.py` in this https://github.com/verdimrc/python-project-skeleton which will automatically detect & prepopulate Juptyer's python path with a few directories.
