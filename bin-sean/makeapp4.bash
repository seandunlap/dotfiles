#!/bin/bash

export LOCAL_TOPLEVEL_DIR=$(git rev-parse --show-toplevel)
export LOCAL_WORKSPACE_DIR=$(dirname $LOCAL_TOPLEVEL_DIR)

export UNIX_USERNAME="sdunlap"
export BUILD_SERVER_HOSTNAME="lc-atl-344.ash.broadcom.net"
export BFC_WORK_FOLDER="/projects/bfc_work1/$UNIX_USERNAME"
export WORKSPACE_NAME=$(basename $LOCAL_WORKSPACE_DIR)
export REMOTE_ECOS_DIR="$BFC_WORK_FOLDER/$WORKSPACE_NAME/rbb_cm/rbb_cm_src/CmDocsisSystem/ecos"

export TFTP_SERVER_HOSTNAME="localhost"

echo
echo "UNIX_USERNAME=$UNIX_USERNAME"
echo "BUILD_SERVER_HOSTNAME=$BUILD_SERVER_HOSTNAME"
echo "BFC_WORK_FOLDER=$BFC_WORK_FOLDER"
echo "LOCAL_TOPLEVEL_DIR=$LOCAL_TOPLEVEL_DIR"
echo "LOCAL_WORKSPACE_DIR=$LOCAL_WORKSPACE_DIR"
echo "WORKSPACE_NAME=$WORKSPACE_NAME"
echo "REMOTE_ECOS_DIR=$REMOTE_ECOS_DIR"
echo

# copy files to build server
git daemon --export-all
rsync -avP --filter=':- .gitignore' $LOCAL_TOPLEVEL_DIR $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME:$BFC_WORK_FOLDER/$WORKSPACE_NAME

# execute makeapp on build server
if [ $? -eq 0 ]
then
	ssh -tq $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME "cd $REMOTE_ECOS_DIR;makeapp "$@""
fi

# copy results to TFTP server
if [ $? -eq 0 ]
then
	rsync -aP --exclude='*.o' --exclude='*.d' $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME:$REMOTE_ECOS_DIR/bcm9*_ipv6 /private/tftpboot
fi
