#!/bin/bash
#
# Run: sudo ./nvidia-modprobe.sh

apt install -y nvidia-modprobe
nvidia-modprobe -c 0 -u
# TODO:
# See: https://www.reddit.com/r/qnap/comments/s7bbv6/fix_for_missing_nvidiauvm_device_devnvidiauvm/
# See: https://github.com/NVIDIA/pyxis/issues/81#issuecomment-1183587951
# See: https://ubuntu-bugs.narkive.com/UvGvw0lZ/bug-1760727-new-dev-nvidia-uvm-tools-not-created

