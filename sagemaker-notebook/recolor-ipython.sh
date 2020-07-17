#!/bin/bash

echo "Change ipython color scheme on something.__class__ from dark blue (nearly invisible) to a more sane color."

mkdir -p /home/ec2-user/.ipython/profile_default/

cat << EOF >> /home/ec2-user/.ipython/profile_default/ipython_config.py
c.TerminalInteractiveShell.highlight_matching_brackets = True

from pygments.token import Name

c.TerminalInteractiveShell.highlighting_style_overrides = {
    Name.Variable: "#B8860B",
}
EOF
