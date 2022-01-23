#!/bin/bash

echo "Change ipython color scheme on something.__class__ from dark blue (nearly invisible) to a more sane color."

mkdir -p ~/.ipython/profile_default/

cat << EOF >> ~/.ipython/profile_default/ipython_config.py
"""
Change default dark blue for "object.__file__" to a more readable color, esp. on dark background.

Find out the correct token type with:

>>> from pygments.lexers import PythonLexer
>>> list(PythonLexer().get_tokens('os.__class__'))
[(Token.Name, 'os'),
 (Token.Operator, '.'),
 (Token.Name.Variable.Magic, '__class__'),
 (Token.Text, '\n')]
"""
c.TerminalInteractiveShell.highlight_matching_brackets = True

from pygments.token import Name

c.TerminalInteractiveShell.highlighting_style_overrides = {
    Name.Variable: "#B8860B",
    Name.Variable.Magic: "#B8860B",  # Unclear why some ipython prefers this.
    Name.Function: "#6fa8dc",        # For IPython 8+ (tone down dark-blue function names)
}
EOF


echo "Add ipython keybindings when connecting from OSX"
IPYTHON_STARTUP_DIR=.ipython/profile_default/startup
IPYTHON_STARTUP_CFG=${IPYTHON_STARTUP_DIR}/01-osx-jupyterlab-keys.py
mkdir -p ~/$IPYTHON_STARTUP_DIR
curl -L \
    https://raw.githubusercontent.com/verdimrc/linuxcfg/master/${IPYTHON_STARTUP_CFG} \
    > ~/$IPYTHON_STARTUP_CFG
