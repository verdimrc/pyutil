#!/bin/bash

################################################################################
# Global vars
################################################################################
INITSMNB_DIR=~/initdlami
SRC_PREFIX=https://raw.githubusercontent.com/verdimrc/pyutil/initdlami/initdlami

declare -a SCRIPTS=(
    CHANGE-ME-setup-my-dlami.sh
    adjust-git.sh
    customize-jlab.sh
    fix-ipython.sh
    fix-osx-keymap.sh
    init.sh
    patch-bash-config.sh
    patch-jupyter-config.sh
    pkgs.sh
    term.sh
    tmux.sh
    vim.sh
)

FROM_LOCAL=0
GIT_USER=''
GIT_EMAIL=''
declare -a EFS=()

declare -a HELP=(
    "[-h|--help]"
    "[-l|--from-local]"
    "[--git-user 'First Last']"
    "[--git-email me@abc.def]"
    "[--efs 'fsid,fsap,mp' [--efs ...]]"
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
            echo "Install initsmnb."
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


################################################################################
# Main
################################################################################
parse_args "$@"
echo "GIT_USER='$GIT_USER'"
echo "GIT_EMAIL='$GIT_EMAIL'"
echo "EFS=$(efs2str)"

mkdir -p $INITSMNB_DIR

if [[ $FROM_LOCAL == 0 ]]; then
    cd $INITSMNB_DIR
    echo "Downloading scripts from ${SRC_PREFIX}/"
    echo "=> ${SRC_PREFIX}/"
    echo
    curl -fsLO $SRC_PREFIX/{$(echo "${SCRIPTS[@]}" | tr ' ' ',')}
    chmod ugo+x ${SCRIPTS[@]}
else
    BIN_DIR=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
    cd $INITSMNB_DIR
    echo "Copying scripts from $BIN_DIR"
    echo "=> ${SRC_PREFIX}/"
    cp -a ${BIN_DIR}/* .
    chmod ugo+x *.sh
fi

echo "Generating setup-my-dlami.sh"
echo "=> git-user / git-email = '$GIT_USER' / '$GIT_EMAIL'"
echo "=> EFS: (fsid,fsap,mountpoint)|... = $(efs2str)"
cat << EOF > setup-my-dlami.sh
#!/bin/bash

# Auto-generated from CHANGE-ME-setup-my-dlami.sh by install-dlami.sh

EOF

sed \
    -e "s/Firstname Lastname/$GIT_USER/" \
    -e "s/first.last@email.abc/$GIT_EMAIL/" \
    -e "s/fsid,fsapid,mountpoint/$(efs2str ' ')/" \
    CHANGE-ME-setup-my-dlami.sh >> setup-my-dlami.sh
chmod ugo+x setup-my-dlami.sh

# Delete mount script if no efs requested.
# WARNING: when testing on OSX, next line must use gsed.
[[ "${#EFS[@]}" < 1 ]] && sed -i "/mount-efs-accesspoint.sh/d" setup-my-dlami.sh

EPILOGUE=$(cat << EOF

###########################################################
# Installation completed.                                 #
#                                                         #
# Apply once to this EC2 instance:                        #
#                                                         #
# ${INITSMNB_DIR}/setup-my-dlami.sh              #
###########################################################
EOF
)
echo -e "${EPILOGUE}\n"

cd $OLDPWD
