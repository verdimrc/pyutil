#!/bin/bash

################################################################################
# Global vars
################################################################################
INITDLAMI_DIR=~/initubuntu
SRC_PREFIX=https://raw.githubusercontent.com/verdimrc/pyutil/master/initubuntu
# Uncomment for testing remote install from local source
#SRC_PREFIX=file:///home/ubuntu/pyutil/initubuntu

declare -a SCRIPTS=(
    TEMPLATE-setup-my-ami.sh
    pkgs.sh
    awscliv2.sh
    duf.sh
    s5cmd.sh
    delta.sh
    adjust-git.sh
    term.sh
    install-gpu-cwagent.sh
    patch-bash-config.sh
    fix-aws-config.sh
    fix-osx-keymap.sh
    install-cdk.sh
    fix-ipython.sh
    install-py-ds.sh
    customize-jlab.sh
    vim.sh
    tmux.sh
    patch-jupyter-config.sh
    update.sh
    prep-instance-store.sh
)

CURL_OPTS="--fail-early -fL"

FROM_LOCAL=0
GIT_USER=''
GIT_EMAIL=''
PY_DS=1
declare -a EFS=()

declare -a HELP=(
    "[-h|--help]"
    "[-l|--from-local]"
    "[--git-user 'First Last']"
    "[--git-email me@abc.def]"
    "[--efs 'fsid,fsap,mp' [--efs ...]]"
    "[--no-py-ds]"
)

################################################################################
# Helper functions
################################################################################
error_and_exit() {
    echo "$@" >&2
    exit 1
}

parse_args() {
    local key
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -h|--help)
            echo "Install initubuntu."
            echo "Usage: $(basename ${BASH_SOURCE[0]}) ${HELP[@]}"
            exit 0
            ;;
        -l|--from-local)
            FROM_LOCAL=1
            shift
            ;;
        --git-user)
            GIT_USER="$2"
            shift 2
            ;;
        --git-email)
            GIT_EMAIL="$2"
            shift 2
            ;;
        --efs)
            [[ "$2" != "" ]] && EFS+=("$2")
            shift 2
            ;;
        --no-py-ds)
            PY_DS=0
            shift
            ;;
        *)
            error_and_exit "Unknown argument: $key"
            ;;
        esac
    done
}

efs2str() {
    local sep="${1:-|}"
    if [[ ${#EFS[@]} -gt 0 ]]; then
        printf "'%s'${sep}" "${EFS[@]}"
    else
        echo "''"
    fi
}

exit_on_download_error() {
    cat << EOF

###############################################################################
# ERROR
###############################################################################
# Could not downloading files from:
#
# $SRC_PREFIX/
#
# Please check and ensure your ec2 instance has the necessary network access to
# download files from the source repository.
###############################################################################
EOF

    exit -1
}


################################################################################
# Main
################################################################################
parse_args "$@"
echo "GIT_USER='$GIT_USER'"
echo "GIT_EMAIL='$GIT_EMAIL'"
echo "EFS=$(efs2str)"

mkdir -p $INITDLAMI_DIR

if [[ $FROM_LOCAL == 0 ]]; then
    cd $INITDLAMI_DIR
    echo "Downloading scripts from ${SRC_PREFIX}/"
    echo "=> ${SRC_PREFIX}/"
    echo
    curl $CURL_OPTS -O $SRC_PREFIX/{$(echo "${SCRIPTS[@]}" | tr ' ' ',')}
    [[ $? == 22 ]] && exit_on_download_error
    chmod ugo+x ${SCRIPTS[@]}
else
    BIN_DIR=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
    cd $INITDLAMI_DIR
    echo "Copying scripts from $BIN_DIR"
    cp -a ${BIN_DIR}/* .
    chmod ugo+x *.sh
fi

echo "Generating setup-my-ami.sh"
echo "=> git-user / git-email = '$GIT_USER' / '$GIT_EMAIL'"
echo "=> EFS: (fsid,fsap,mountpoint)|... = $(efs2str)"
cat << EOF > setup-my-ami.sh
#!/bin/bash

# Auto-generated from TEMPLATE-setup-my-ami.sh by install-ami.sh

EOF

sed \
    -e "s/Firstname Lastname/$GIT_USER/" \
    -e "s/first.last@email.abc/$GIT_EMAIL/" \
    -e "s/fsid,fsapid,mountpoint/$(efs2str ' ')/" \
    TEMPLATE-setup-my-ami.sh >> setup-my-ami.sh
chmod ugo+x setup-my-ami.sh

# Delete mount script if no efs requested.
# WARNING: when testing on OSX, next line must use gsed.
[[ "${#EFS[@]}" < 1 ]] && sed -i "/mount-efs-accesspoint.sh/d" setup-my-ami.sh

# Skip installing pyenv if this is requested.

[[ "${PY_DS}" < 1 ]] && sed -i "s|^\(.*/install-py-ds.sh\)$|#\1|" setup-my-ami.sh

EPILOGUE=$(cat << EOF

########################################################
# Installation completed.                              #
#                                                      #
# Apply just ONCE to this EC2 instance:                #
#                                                      #
#     ~/initubuntu/setup-my-ami.sh                     #
#                                                      #
#                                                      #
# You can also run the setup script under screen,      #
# which is useful when using the connecting to the     #
# EC2 via SSM web console:                             #
#                                                      #
#     screen -dm bash -c ~/initubuntu/setup-my-ami.sh  #
#                                                      #
#     # ctrl-a-d                                       #
#     # screen -ls                                     #
#     # screen -x                                      #
#                                                      #
# See also ~/initubuntu/update.sh for an example on    #
# updating this EC2 instance.                          #
#                                                      #
########################################################
#                                                      #
# On an instance with 1+ instance stores, run below    #
# after start-up or reboot:                            #
#                                                      #
#     ~/initubuntu/prep-instance-store.sh              #
#                                                      #
# See also: ~/PREP_INSTANCE_STORE.txt                  #
########################################################
EOF
)
echo -e "${EPILOGUE}\n"

cd $OLDPWD
