"""An example to load dynamic libraries (.so files).

See: https://serverlesscode.com/post/deploy-scikitlearn-on-lamba/
"""

import os
import ctypes

# In this example, it's assumed that LD_LIBRARY_PATH strictly contains
# only .a (static libraries) and .so (dynamic libraries) files.
LD_LIBRARY_PATH = 'lib'

for d, dirs, files in os.walk(LD_LIBRARY_PATH):
    for f in files:
        if f.endswith('.a'):
            continue
        ctypes.cdll.LoadLibrary(os.path.join(d, f))

####
# From this point onwards, sklearn needs its .so files loaded beforehand.

import sklearn

def handler(event, context):
    # do sklearn stuff here
    return {'yay': 'done'}
