#!/bin/bash
#
# This script will start with an rbb_cm clone, make a mirror clone of it,
# and filter out all of the files and folders in the skip-list that we
# do not distribute to the customer.
#
# This is not just a deletion of the files from the mirror clone.
# Rather, it is a rewrite of history to completely purge the skiplist
# files and folders from the GIT history of the clone created for ths
# release.  It uses a popular and widely praised package called BFG
# to do the filtering.
#
# https://github.com/IBM/BluePic/wiki/Using-BFG-Repo-Cleaner-tool-to-remove-sensitive-files-from-your-git-repo
#
set -x

export TOPLEVEL_DIR=$(git rev-parse --show-toplevel)
export WORKSPACE_DIR=$(dirname $TOPLEVEL_DIR)
export CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export RELEASE_WORKSPACE_DIR=$WORKSPACE_DIR.$CURRENT_BRANCH.release

if [ -d $RELEASE_WORKSPACE_DIR ]; then
 #   rm -rf $RELEASE_WORKSPACE_DIR
    rm $log_file
    mkdir $RELEASE_WORKSPACE_DIR
fi

# send this script output to both terminal and log file
export log_file=$RELEASE_WORKSPACE_DIR$RELEASE_WORKSPACE_DIR.log
exec >> $log_file 1>&1 && tail $log_file

# make a mirror clone of the repo we want to start with
cd $RELEASE_WORKSPACE_DIR
git clone --mirror $TOPLEVEL_DIR/.git/ rbb_cm.git

# remove all except the current customer branch so they cannot
# see other customer branches
# clean up unreachable blobs, to compress the repo and further
# speed up the history re-write.
cd rbb_cm.git
git reflog expire --expire=now refs/heads/$CURRENT_BRANCH
git fsck --unreachable
git prune
git gc

# filter folders
bfg --no-blob-protection --delete-folders 'rbb_cm_lib'
bfg --no-blob-protection --delete-folders 'rbb_win32_lib'
bfg --no-blob-protection --delete-folders 'BfcDocs'
bfg --no-blob-protection --delete-folders 'Diagnostics'
bfg --no-blob-protection --delete-folders 'SysTest'
bfg --no-blob-protection --delete-folders 'BrcmInternalDebug'
bfg --no-blob-protection --delete-folders 'Win32'
bfg --no-blob-protection --delete-folders 'CfgRls'
bfg --no-blob-protection --delete-folders 'MessageLogZapper'
bfg --no-blob-protection --delete-folders 'WebUiManager'
bfg --no-blob-protection --delete-folders 'CableHome'
bfg --no-blob-protection --delete-folders 'bsp_bcm9338*'
bfg --no-blob-protection --delete-folders 'Wasu'
bfg --no-blob-protection --delete-folders 'CmBootloader'
bfg --no-blob-protection --delete-folders 'MediaServer'
bfg --no-blob-protection --delete-folders 'MtaExtensionApi'
bfg --no-blob-protection --delete-folders 'ResidentialGateway'
bfg --no-blob-protection --delete-folders 'Smta*'
bfg --no-blob-protection --delete-folders 'SpsCableHomeSystem'
bfg --no-blob-protection --delete-folders 'Stb*'
bfg --no-blob-protection --delete-folders 'cm_bsp_v2'
bfg --no-blob-protection --delete-folders 'eRouter'

# filter files
bfg --no-blob-protection --delete-files 'BcmBfcRegress*'
bfg --no-blob-protection --delete-files '*Win32*.*'
bfg --no-blob-protection --delete-files 'BfcBigPicture.txt'
bfg --no-blob-protection --delete-files 'BfcReleaseNotes.txt'
bfg --no-blob-protection --delete-files 'readme.txt'
bfg --no-blob-protection --delete-files 'BRCM-CABLEDATA-EXPERIMENTAL-MIB.mib'
bfg --no-blob-protection --delete-files 'bcm9338*'
bfg --no-blob-protection --delete-files 'if_bcm_src.c'
bfg --no-blob-protection --delete-files 'Bfc3380fpga.mak'
bfg --no-blob-protection --delete-files 'BfcDiagnostics.mak'
bfg --no-blob-protection --delete-files 'BfcIoplib.mak'
bfg --no-blob-protection --delete-files 'BroadcomBcm9338*'
bfg --no-blob-protection --delete-files 'MessageLogZapper.exe'

# purge the filtered files from the reflog
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# prepare several flavors of tarballs
cd ..

# git repo for cloning by customer
tar -cvf $RELEASE_WORKSPACE_DIR.git-repo.tgz rbb_cm.git/

# source code only
git clone rbb_cm.git
tar -cvf $RELEASE_WORKSPACE_DIR.source-code.tgz --exclude ".git" --exclude "*/.git/*" rbb_cm/

# both source code and GIT repo
tar -cvf $RELEASE_WORKSPACE_DIR.source-code+git-repo.tgz rbb_cm/.git rbb_cm.git/