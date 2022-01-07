#!/bin/bash

JUPYTER_CONFIG_ROOT=~/.jupyter/lab/user-settings/\@jupyterlab

# Show trailing space is brand-new since JLab-3.2.0
# See: https://jupyterlab.readthedocs.io/en/3.2.x/getting_started/changelog.html#id22
mkdir -p $JUPYTER_CONFIG_ROOT/notebook-extension/
cat << EOF > $JUPYTER_CONFIG_ROOT/notebook-extension/tracker.jupyterlab-settings
{
    // Notebook
    // @jupyterlab/notebook-extension:tracker
    // Notebook settings.
    // **************************************
    "codeCellConfig": {
        "rulers": [80, 100],
        "codeFolding": true,
        "lineNumbers": true,
        "lineWrap": "off",
        "showTrailingSpace": true
    },
    "markdownCellConfig": {
        "rulers": [80, 100],
        "codeFolding": true,
        "lineNumbers": true,
        "lineWrap": "off",
        "showTrailingSpace": true
    },
    "rawCellConfig": {
        "rulers": [80, 100],
        "lineNumbers": true,
        "lineWrap": "off",
        "showTrailingSpace": true
    }
}
EOF

mkdir -p $JUPYTER_CONFIG_ROOT/fileeditor-extension/
cat << EOF > $JUPYTER_CONFIG_ROOT/fileeditor-extension/plugin.jupyterlab-settings
{
    // Text Editor
    // @jupyterlab/fileeditor-extension:plugin
    // Text editor settings.
    // ***************************************
    "editorConfig": {
        "fontSize": 11,
        "rulers": [80, 100],
        "codeFolding": true,
        "lineNumbers": true,
        "lineWrap": "off",
        "showTrailingSpace": true
    }
}
EOF

mkdir -p $JUPYTER_CONFIG_ROOT/apputils-extension/themes.jupyterlab-settings
cat << EOF > $JUPYTER_CONFIG_ROOT/apputils-extension/themes.jupyterlab-settings
{
    // Theme
    // @jupyterlab/apputils-extension:themes
    // Theme manager settings.
    // *************************************

    // Theme CSS Overrides
    // Override theme CSS variables by setting key-value pairs here
    "overrides": {
        "code-font-size": "11px",
        "content-font-size1": "14px",
        "ui-font-size1": "12px"
    }
}
EOF

# macOptionIsMeta is brand-new since JLab-3.0.
# See: https://jupyterlab.readthedocs.io/en/3.0.x/getting_started/changelog.html#other
mkdir -p $JUPYTER_CONFIG_ROOT/terminal-extension/
cat << EOF > $JUPYTER_CONFIG_ROOT/terminal-extension/plugin.jupyterlab-settings
{
    // Terminal
    // @jupyterlab/terminal-extension:plugin
    // Terminal settings.
    // *************************************

    // Font size
    // The font size used to render text.
    "fontSize": 10,

    // Theme
    // The theme for the terminal.
    "theme": "dark",

    // Treat option as meta key on macOS (new in JLab-3.0)
    // Option key on macOS can be used as meta key. This enables to use shortcuts such as option + f
    // to move cursor forward one word
    "macOptionIsMeta": true
}
EOF

# Undo the old "mac-option-is-meta" mechanism designed for jlab<3.0.
echo "# JLab-3 + macOptionIsMeta deprecates fix-osx-keymap.sh" > ~/.inputrc
[[ -f ~/.ipython/profile_default/startup/01-osx-jupyterlab-keys.py ]] \
    && rm ~/.ipython/profile_default/startup/01-osx-jupyterlab-keys.py

# Show command palette on lhs navbar, similar behavior to smnb.
mkdir -p $JUPYTER_CONFIG_ROOT/apputils-extension/
cat << EOF > $JUPYTER_CONFIG_ROOT/apputils-extension/palette.jupyterlab-settings
{
    // Command Palette
    // @jupyterlab/apputils-extension:palette
    // Command palette settings.
    // **************************************

    // Modal Command Palette
    // Whether the command palette should be modal or in the left panel.
    "modal": false
}
EOF

# Auto-apply black & isort when saving on notebook editor (but sadly, not on text editor).
mkdir -p $JUPYTER_CONFIG_ROOT/../\@ryantam626/jupyterlab_code_formatter/
cat << EOF > $JUPYTER_CONFIG_ROOT/../\@ryantam626/jupyterlab_code_formatter/settings.jupyterlab-settings
{
    // Jupyterlab Code Formatter
    // @ryantam626/jupyterlab_code_formatter:settings
    // Jupyterlab Code Formatter settings.
    // **********************************************

    // Black Config
    // Config to be passed into black's format_str function call.
    "black": {
        "line_length": 100
    },

    // Auto format config
    // Auto format code when save the notebook.
    "formatOnSave": true,

    // Isort Config
    // Config to be passed into isort's SortImports function call.
    "isort": {
        "multi_line_output": 3,
        "include_trailing_comma": true,
        "force_grid_wrap": 0,
        "use_parentheses": true,
        "line_length": 100
    }
}
EOF
