#!/bin/bash

################################################################################
# Global vars
################################################################################
#INITSMNB_DIR=/home/ec2-user/SageMaker/initsmnb
INITSMNB_DIR=/tmp/ec2-user/SageMaker/initsmnb
SRC_PREFIX=https://raw.githubusercontent.com/verdimrc/pyutil/master/sagemaker-notebook

declare -a SCRIPTS=(
    CHANGE-ME-setup-my-sagemaker.sh
    adjust-sm-git.sh
    change-fontsize.sh
    fix-ipython.sh
    fix-osx-keymap.sh
    init-vim.sh
    mount-efs-accesspoint.sh
    patch-bash-config.sh
    patch-jupyter-config.sh
)

GIT_USER=''
GIT_EMAIL=''
declare -a EFS=()

declare -a HELP=(
    "[-h|--help]"
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
    if [[ ${#EFS[@]} -gt 0 ]]; then
        printf "'%s'|" "${EFS[@]}"
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
cd $INITSMNB_DIR

echo "Downloading scripts from https://github.com/verdimrc/pyutil/tree/master/sagemaker-notebook/"
echo "=> ${SRC_PREFIX}/"
echo
curl -fsLO $SRC_PREFIX/{$(echo "${SCRIPTS[@]}" | tr ' ' ',')}
chmod ugo+x ${SCRIPTS[@]}

echo "Generating setup-my-sagemaker.sh"
echo "=> git-user / git-email = '$GIT_USER' / '$GIT_EMAIL'"
echo "=> fsid / fsap-id / mountpoint = '$3' / '$4' / '$5'"
echo "=> EFS: (fsid,fsap,mountpoint)|... = $(efs2str)"
cat << EOF > setup-my-sagemaker.sh
#!/bin/bash

# Auto-generated from CHANGE-ME-setup-my-sagemaker.sh by install-initsmnb.sh

EOF

# TODO:
# for i in efs:
#     echo mount-efs-accesspoint.sh something-something >> setup-my-sagemaker.sh
#
# TODO: update mount-efs-accesspoint.sh to deal with multiple efs
sed \
    -e "s/Firstname Lastname/$GIT_USER/" \
    -e "s/first.last@email.abc/$GIT_EMAIL/" \
    -e "s/fsid/$3/" \
    -e "s/fsapid/$4/" \
    -e "s/mountpoint/$5/" \
    CHANGE-ME-setup-my-sagemaker.sh >> setup-my-sagemaker.sh
chmod ugo+x setup-my-sagemaker.sh
[[ "${#EFS[@]}" < 1 ]] && gsed -i "/mount-efs-accesspoint.sh/d" setup-my-sagemaker.sh

EPILOGUE=$(cat << EOF

###########################################################
# Installation completed.                                 #
#                                                         #
# To change this session, run:                            #
#                                                         #
# ${INITSMNB_DIR}/setup-my-sagemaker.sh #
#                                                         #
# On notebook restart, also run that same command.        #
###########################################################
EOF
)
echo -e "${EPILOGUE}\n"

cd $OLDPWD
