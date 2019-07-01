#!/bin/bash

# build server
export UNIX_USERNAME="sdunlap"
export BUILD_SERVER_HOSTNAME="rbbsw"
export TFTP_SERVER_HOSTNAME="localhost"
export TFTP_SERVER_ROOT_DIR="/"

export LOCAL_TOPLEVEL_DIR=$(git rev-parse --show-toplevel)
export LOCAL_WORKSPACE_DIR=$(dirname $LOCAL_TOPLEVEL_DIR)
export LOCAL_HOSTNAME=$(scutil --get ComputerName)
export HOST=$UNIX_USERNAME@$BUILD_SERVER_HOSTNAME
export BFC_WORK_FOLDER="/projects/bfc_work1/$UNIX_USERNAME"
export WORKSPACE_NAME=$(basename $LOCAL_WORKSPACE_DIR)
export REMOTE_TOPLEVEL_DIR="$BFC_WORK_FOLDER/$WORKSPACE_NAME/CM_Prod_6.1.2_clone_sdunlap/rbb_cm"
export REMOTE_ECOS_DIR="$REMOTE_TOPLEVEL_DIR/rbb_cm_src/CmDocsisSystem/ecos"
export CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export LOCAL_HEAD=$(git rev-parse --abbrev-ref HEAD)
#export REMOTE_HEAD=$(ssh -tqP $($HOST) ("cd $(REMOTE_ECOS_DIR);git rev-parse --abbrev-ref HEAD"))

# enable command printing for debug
set -x

# if local and remote have different heads, push all refs to remote and check HEAD
#if [ $LOCAL_HEAD != $REMOTE_HEAD ]
#then
    git push -f $HOST:$REMOTE_TOPLEVEL_DIR
	# check out local HEAD so they match
    ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR;git reset --hard HEAD"
#fi

cd $LOCAL_TOPLEVEL_DIR

# make a list of modified files and put it in a temporary file
MODIFIED_FILES=$(mktemp)
git ls-files --modified > $MODIFIED_FILES

# copy the modified files on top of the checked out branch on the remote
rsync -av --files-from=$MODIFIED_FILES ./ $HOST:$REMOTE_TOPLEVEL_DIR
rm $MODIFIED_FILES
# execute makeapp on the remote
ssh -tqP $HOST "cd $REMOTE_ECOS_DIR;./makeapp "$@""

# copy results to TFTP server
if [ $? -eq 0 ]
then
	rsync -aP $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME:$REMOTE_ECOS_DIR/$1Bx_ipv6/ecram_sto.bin /private/tftpboot/$1Bx_ipv6
fi