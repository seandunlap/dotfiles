#!/bin/bash

# enable command printing for this script debugging
#set -x

LOCAL_TOPLEVEL_DIR=$(git rev-parse --show-toplevel)

cd $LOCAL_TOPLEVEL_DIR

# build server name
UNIX_USERNAME="sd903151"
BUILD_SERVER_HOSTNAME="rbbswbld"
BFC_WORK_FOLDER="/projects/bfc_work1/sd903151"
LOCAL_WORKSPACE_DIR="/Users/sd903151/workspace"
REMOTE_WORKSPACE_DIR="/projects/bfc_work1/sdunlap/workspace"

TFTP_SERVER_HOSTNAME_LOCAL="localhost"
TFTP_SERVER_ROOT_DIR="/private/tftpboot"
TFTP_SERVER_HOSTNAME_REMOTE="vaainas05.ash.broadcom.net"
TFTP_SERVER_REMOTE_ROOT_DIR="/homeproj/sde_systems/tftpboot/usr/sdunlap"

# get local clone top-level directory
#LOCAL_WORKSPACE_DIR=$(dirname $LOCAL_TOPLEVEL_DIR)
HOST=$UNIX_USERNAME@$BUILD_SERVER_HOSTNAME

if [ "$1" == "-d" ]; then
	REMOTE_WORKSPACE_DIR="$BFC_WORK_FOLDER/$2"
	shift 2
elif [ "$1" == "-l" ]; then
	BUILD_LIBS=1
	shift 1
fi

REMOTE_TOPLEVEL_DIR="$REMOTE_WORKSPACE_DIR/rbb_cm"
REMOTE_ECOS_DIR="$REMOTE_TOPLEVEL_DIR/rbb_cm_src/CmDocsisSystem/ecos"
LOCAL_HEAD=$(git rev-parse --short HEAD)
LOCAL_HEAD_DESC=$(git log -1 --oneline HEAD)

# set up remote workspace, if needed
if [ $? != 0 ]; then
    ssh -tqP $HOST "mkdir $REMOTE_TOPLEVEL_DIR"
fi
ssh $HOST "test -e $REMOTE_TOPLEVEL_DIR"
if [ $? != 0 ]; then
    ssh -tqP $HOST "mkdir $REMOTE_TOPLEVEL_DIR"
fi
ssh $HOST "test -e $REMOTE_TOPLEVEL_DIR/.git/"
if [ $? != 0 ]; then
	ssh -tqP $HOST "git init $REMOTE_TOPLEVEL_DIR"
fi

ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR;git reset --hard"
REMOTE_HEAD=$(ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR;git rev-parse --short HEAD")

# set up remote workspace, if needed
if [ $? != 0 ]; then
    ssh -tqP $HOST "mkdir $REMOTE_TOPLEVEL_DIR"
fi
ssh $HOST "test -e $REMOTE_TOPLEVEL_DIR"
if [ $? != 0 ]; then
    ssh -tqP $HOST "mkdir $REMOTE_TOPLEVEL_DIR"
fi
ssh $HOST "test -e $REMOTE_TOPLEVEL_DIR/.git/"
if [ $? != 0 ]; then
	ssh -tqP $HOST "git init $REMOTE_TOPLEVEL_DIR"
fi

if [ LOCAL_HEAD != REMOTE_HEAD ]; then

	git push $HOST:$REMOTE_WORKSPACE_DIR/rbb_cm/
	if [ $? != 0 ]; then
		echo "Failed to push to remote repo"
		exit 1
	fi

	ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR;git reset --hard $LOCAL_HEAD"
fi

# make a temp file to hold the list of modified file names
MODIFIED_FILES=$(mktemp)

# write modified file list into temp file
cd $LOCAL_TOPLEVEL_DIR
git ls-files --modified > $MODIFIED_FILES

if [ -s $MODIFIED_FILES ]; then
	echo -e "\nLocally modified files:"
	cat $MODIFIED_FILES
	rsync -a --files-from=$MODIFIED_FILES ./ $HOST:$REMOTE_TOPLEVEL_DIR
	echo -e "\nRemotely modified files:"
	ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR;git ls-files --modified"
	echo
fi

# cleanup temp file
rm $MODIFIED_FILES

if [ "$BUILD_LIBS" == "1" ]; then
	ssh -tqP $HOST "cd $REMOTE_ECOS_DIR;./makeapp bcm93390dcm ioplib"
	#ssh -tqP $HOST "cd $REMOTE_ECOS_DIR;./makeapp bcm93390dcm AckCelLib"
	#ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR/rbb_cm_lib/OpenSSH; make"
	#ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR/rbb_cm_lib/NetSNMP/Source/net-snmp-5.0.9; makenetsnmp"
	#ssh -tqP $HOST "cd $REMOTE_TOPLEVEL_DIR/rbb_cm_ecos/ecos-src/bcm33xx_ipv6; build.bash"

	REMOTE_ECOS_LIBDIR=$REMOTE_TOPLEVEL_DIR/rbb_cm_src/Bfc/LibSupport/eCos/bcm33xx_ipv6_install/lib/
	LOCAL_ECOS_LIBDIR=$LOCAL_TOPLEVEL_DIR/rbb_cm_src/Bfc/LibSupport/eCos/bcm33xx_ipv6_install/lib/
	#scp $HOST:$REMOTE_TOPLEVEL_DIR/rbb_cm_src/Bfc/LibSupport/AckCel/AckCel.eCos.a $LOCAL_TOPLEVEL_DIR/rbb_cm_src/Bfc/LibSupport/AckCel/
	#scp $HOST:$REMOTE_ECOS_LIBDIR/libextras.a $LOCAL_LIBDIR
	#scp $HOST:$REMOTE_ECOS_LIBDIR/libtarget.a $LOCAL_LIBDIR
fi

ssh -tqP $HOST "cd $REMOTE_ECOS_DIR;./makeapp "$@""

if [ $? != 0 ]; then
	echo "Build failed."
else
	echo "Copying ecram_sto.bin to local TFTP server"
	scp $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME:$REMOTE_ECOS_DIR/$1Bx_ipv6/monolith.bin /private/tftpboot
	scp $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME:$REMOTE_ECOS_DIR/$1Bx_ipv6/ecram_sto.bin /private/tftpboot
	scp $UNIX_USERNAME@$BUILD_SERVER_HOSTNAME:$REMOTE_ECOS_DIR/$1Bx_ipv6/ecram.shortmap /private/tftpboot
fi
