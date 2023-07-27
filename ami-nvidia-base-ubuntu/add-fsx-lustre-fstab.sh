#!/bin/bash

set -euo pipefail

# Generic script to add mount point of Amazon FSx Lustre client on Ubuntu AMI. Run this as root.

################################################################################
# 000: Sanity check the Ubuntu version
################################################################################
[[ $EUID -ne 0 ]] && { echo 'Script is NOT run as root. Exiting...' ; exit -1 ; }
[[ ! $(lsb_release -is) =~ "Ubuntu" ]] && echo "This script is for Ubuntu only. Exiting..."

if [[ -t 1 ]]; then
    COLOR_RED="\033[1;31m"
    COLOR_GREEN="\033[1;32m"
    COLOR_YELLOW="\033[1;33m"
    COLOR_OFF="\033[0m"
else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_OFF=""
fi

declare -a SUPPORTED_UBUNTU=( 20.04 22.04 )
if [[ ! " ${SUPPORTED_UBUNTU[*]} " =~ " $(lsb_release -rs) " ]]; then
    echo -e "${COLOR_YELLOW}WARNING: Ubuntu-$(lsb_release -rs) not in supported versions. Script may break.${COLOR_OFF}

Supported Ubuntu versions: [$(echo ${SUPPORTED_UBUNTU[@]} | sed 's/ /, /g')].
"
fi

parse_args() {
    while [[ $# -gt 0 ]]; do
        local key="$1"
        case $key in
        -h|--help)
            echo "Add an FSx Lustre entry to /etc/fstab"
            echo "Usage: $(basename ${BASH_SOURCE[0]}) --fsx-dns <FSX_DNS> --fsx-mountname <FSX_MOUNTNAME> --fsx-mountdir <FSX_MOUNTDIR>"
            exit 0
            ;;
        --fsx-dns)
            FSX_DNS="$2"
            shift 2
            ;;
        --fsx-mountname)
            FSX_MOUNTNAME="$2"
            shift 2
            ;;
        --fsx-mountdir)
            FSX_MOUNTDIR="$2"
            shift 2
            ;;
        *)
            echo "Error: unknown argument: $1"
            exit -1
            ;;
        esac
    done
}

set +u
parse_args "$@"
[[ -n "$FSX_DNS" && -n "$FSX_MOUNTNAME" && -n "$FSX_MOUNTDIR" ]] || { echo "Require the dns, mountname, and mountdir" ; exit -1 ; }
set -u


################################################################################
# 010: Here we go...
################################################################################
[[ $(lsb_release -rs) < 22.04 ]] && REQUIRES_SVC=network.service || REQUIRES_SVC=systemd-networkd-wait-online.service

# Add template entry for usability
[[ $(grep "^# FSX_DNS_NAME@tcp:" /etc/fstab 2> /dev/null) ]] \
    || echo \
        "# FSX_DNS_NAME@tcp:/FSX_MOUNT_NAME <LOCAL_MOUNT_DIR> lustre defaults,nofail,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=${REQUIRES_SVC} 0 0" \
        >> /etc/fstab

if [[ ! $FSX_DNS =~ "fsx_file_system_dns_name" ]]; then
    # Comment out any old entry.
    sed -i "s|^\([^#].* $FSX_MOUNTDIR lustre .*$\)|#\1|g" /etc/fstab

    # Add entry for the specific volume
    echo "$FSX_DNS@tcp:/$FSX_MOUNTNAME $FSX_MOUNTDIR lustre defaults,nofail,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=${REQUIRES_SVC} 0 0" >> /etc/fstab
    mkdir -p ${FSX_MOUNTDIR}/
    cat /etc/fstab
fi


################################################################################
# 020: Epilog - on-screen reminder
################################################################################
systemctl daemon-reload
systemctl restart remote-fs.target
