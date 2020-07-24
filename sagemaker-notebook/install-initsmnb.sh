#!/bin/bash

INITSMNB_DIR=/home/ec2-user/SageMaker/initsmnb
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

mkdir -p $INITSMNB_DIR
cd $INITSMNB_DIR

echo "Downloading scripts from https://github.com/verdimrc/pyutil/tree/master/sagemaker-notebook/"
echo "=> ${SRC_PREFIX}/"
echo
curl -fsLO $SRC_PREFIX/{$(echo "${SCRIPTS[@]}" | tr ' ' ',')}
chmod ugo+x ${SCRIPTS[@]}

echo "Generating setup-my-sagemaker.sh"
echo "=> git-user / git-email = '$1' / '$2'"
echo "=> fsid / fsap-id / mountpoint = '$3' / '$4' / '$5'"
cat << EOF > setup-my-sagemaker.sh
#!/bin/bash

# Auto-generated from CHANGE-ME-setup-my-sagemaker.sh by install-initsmnb.sh

EOF

sed \
    -e "s/Firstname Lastname/$1/" \
    -e "s/first.last@email.abc/$2/" \
    -e "s/fsid/$3/" \
    -e "s/fsapid/$4/" \
    -e "s/mountpoint/$5/" \
    CHANGE-ME-setup-my-sagemaker.sh >> setup-my-sagemaker.sh
chmod ugo+x setup-my-sagemaker.sh


EPILOGUE=$(cat << EOF

###########################################################
# Installation completed.                                 #
#                                                         #
# To change this session, run:                            #
#                                                         #
# /home/ec2-user/SageMaker/initsmnb/setup-my-sagemaker.sh #
#                                                         #
# On notebook restart, also run that same command.        #
###########################################################
EOF
)
echo -e "${EPILOGUE}\n"

cd $OLDPWD
