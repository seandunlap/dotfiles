#!/bin/bash

# 2016_01_13 - Text prompt changes for new makefile structure

VERSION="1.11"

usage() {
cat <<EOF

Usage: `basename $0` [-h ] [ -a apps_branch ] [ -b branch_name ]
                        [ -d main_dir ] [ -k kernel_branch ]
                        [ -m main_branch ] [ -r rootfs_branch ]

  All arguments are optional. Default settings will be used if not specified.

  -h: Print this message

  -a: Specify branch to checkout in apps (rg_apps) repository
  -b: Specify single branch to be used for all repositories
  -d: Specify directory (will be created) into which clone will take place
  -k: Specify branch to checkout in kernel repository
  -m: Specify branch to checkout in main (top-level) repository
  -r: Specify branch to checkout in rootfs repository

  Examples:

  To checkout the same branch "master" in all repositories except for "test"
  in the kernel repository
      `basename $0` -b master -k test

  To checkout the default branch, "$BRANCH_DEFAULT", in all repositories except
  for "fixes" in the rootfs repository and clone into the "myrepo" directory
      `basename $0` -r fixes -d myrepo

EOF

exit 1
}

check_branch() {
CHK_REPO=$1
CHK_BRANCH=$2

( git ls-remote -h $GIT_USER@$GIT_SERVER:$CHK_REPO | grep refs/heads/$CHK_BRANCH )

CHK_RET=$?

if [ $CHK_RET -eq 1 ]
then
  echo -e "\n*** Error: No such branch $CHK_BRANCH in repo $CHK_REPO ***\n"
fi

return $CHK_RET
}

print_pre_info() {
cat <<EOF

Cloning eRouter code to <$BASE_DIR>
    Main directory:      <$MAINDIR>            Branch: <$BRANCH_MAIN>
    RG apps directory:   <$APPS_PATH>    Branch: <$BRANCH_APPS>
    STB roofs directory: <$ROOTFS_PATH>     Branch: <$BRANCH_ROOTFS>
    Kernel directory:    <$KERNEL_PATH>      Branch: <$BRANCH_KERNEL>
    Aeolus directory:    <$AEOLUS_PATH>     Branch: <$BRANCH_AEOLUS>

EOF
}

set_hooks() {
echo "Setting up pre-commit hooks to catch whitespace errors"

( cd $BASE_DIR/$MAINDIR && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit && \
cd $BASE_DIR/$APPS_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit && \
cd $BASE_DIR/$ROOTFS_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit && \
cd $BASE_DIR/$KERNEL_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit ) || \
echo -e "\n*** Error setting up pre-commit hooks - proceeding with default hooks ***"
}

print_post_info() {
cat <<EOF

To build, issue the following commands:

    cd $MAINDIR
    make defaults-<CHIP> all

EOF
}

do_clone() {
# Get the sources from Git
( git clone -b $BRANCH_MAIN $GIT_USER@$GIT_SERVER:$REPO_MAIN $MAINDIR && echo && \
  cd $MAINDIR && git clone -b $BRANCH_ROOTFS $GIT_USER@$GIT_SERVER:$REPO_ROOTFS $ROOTFS_DIRNAME && echo && \
  git clone -b $BRANCH_KERNEL $GIT_USER@$GIT_SERVER:$REPO_KERNEL $KERNEL_DIRNAME && echo && \
  git clone -b $BRANCH_APPS $GIT_USER@$GIT_SERVER:$REPO_APPS $APPS_DIRNAME && echo && \
  git clone -b $BRANCH_AEOLUS $GIT_USER@$GIT_SERVER:$REPO_AEOLUS $AEOLUS_DIRNAME && echo && \
  return 0 ) || return 1
}

do_clone_ro() {
GIT_USER=git://

# Get the sources from Git
( git clone -b $BRANCH_MAIN $GIT_USER$GIT_SERVER/$REPO_MAIN $MAINDIR && echo && \
  cd $MAINDIR && git clone -b $BRANCH_ROOTFS $GIT_USER$GIT_SERVER/$REPO_ROOTFS $ROOTFS_DIRNAME && echo && \
  git clone -b $BRANCH_KERNEL $GIT_USER$GIT_SERVER/$REPO_KERNEL $KERNEL_DIRNAME && echo && \
  git clone -b $BRANCH_APPS $GIT_USER$GIT_SERVER/$REPO_APPS $APPS_DIRNAME && echo && \
  git clone -b $BRANCH_AEOLUS $GIT_USER$GIT_SERVER/$REPO_AEOLUS $AEOLUS_DIRNAME && echo && \
  return 0 ) || return 1
}


#
# Begin script execution
#

BASE_DIR=`pwd`

BRANCH_DEFAULT=develop
BRANCH_MAIN=$BRANCH_DEFAULT
BRANCH_ROOTFS=$BRANCH_DEFAULT
BRANCH_KERNEL=$BRANCH_DEFAULT
BRANCH_APPS=$BRANCH_DEFAULT
BRANCH_AEOLUS=$BRANCH_DEFAULT

MAINDIR_DEFAULT=erouter
MAINDIR=$MAINDIR_DEFAULT

GIT_SERVER=git-and-01.and.broadcom.com
GIT_USER=gitcmand

REPO_MAIN=erouter-314.git
REPO_ROOTFS=erouter-stbrootfs.git
REPO_KERNEL=erouter-linux-314.git
REPO_APPS=erouter-userspace.git
REPO_AEOLUS=aeolus.git

REPO_LIST="$REPO_MAIN $REPO_ROOTFS $REPO_KERNEL $REPO_APPS"

CLONE_RO=0

echo -e "\neRouter clone script version: $VERSION\n"
echo "Default branch:      $BRANCH_DEFAULT"
echo -e "Default directory:   $MAINDIR_DEFAULT\n"

while getopts ":a:b:d:hk:m:r:R" opt; do
  case $opt in
      a)
        echo "Setting apps branch: $OPTARG"
        check_branch $REPO_APPS $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_APPS=$OPTARG
        ;;
      b)
        echo "Setting all branch: $OPTARG"
        B_RET=0
        for i in $REPO_LIST; do
          check_branch $i $OPTARG
          B_RET+=$?
        done
        if [ $B_RET -ne 0 ]
        then
          exit $B_RET
        else
          BRANCH_MAIN=$OPTARG
          BRANCH_ROOTFS=$OPTARG
          BRANCH_KERNEL=$OPTARG
          BRANCH_APPS=$OPTARG
          BRANCH_AEOLUS=$OPTARG
        fi
        ;;
      d)
        echo "Setting base directory: $OPTARG"
        MAINDIR=$OPTARG
        ;;
      h)
        usage
        exit 0
        ;;
      k)
        echo "Setting kernel branch: $OPTARG"
        check_branch $REPO_KERNEL $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_KERNEL=$OPTARG
        ;;
      m)
        echo "Setting main branch: $OPTARG"
        check_branch $REPO_MAIN $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_MAIN=$OPTARG
        ;;
      r)
        echo "Setting rootfs branch: $OPTARG"
        check_branch $REPO_ROOTFS $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_ROOTFS=$OPTARG
        ;;
      :)
        echo "Option \"$OPTARG\" requires an argument"
        exit 1
        ;;
      *)
        echo "Unimplemented option chosen"
        exit 1
        ;;   # Default
  esac
done

APPS_DIRNAME=rg_apps
APPS_PATH=$MAINDIR/$APPS_DIRNAME

ROOTFS_DIRNAME=rootfs
ROOTFS_PATH=$MAINDIR/$ROOTFS_DIRNAME

KERNEL_DIRNAME=linux
KERNEL_PATH=$MAINDIR/$KERNEL_DIRNAME

AEOLUS_DIRNAME=aeolus
AEOLUS_PATH=$MAINDIR/$AEOLUS_DIRNAME

print_pre_info

if [ $CLONE_RO -eq 0 ]
then
  do_clone
  CLONE_RET=$?
else
  do_clone_ro
  CLONE_RET=$?
fi

if [ $CLONE_RET -eq 0 ]
then
  if [ $CLONE_RO -eq 1 ]
  then
    echo -e "\nClone operations were successful (READ-ONLY)\n"
  else
    echo -e "\nClone operations were successful\n"
  fi
  set_hooks
  print_post_info
else
  echo -e "\n*** Error cloning git repository ***\n"
  exit 1
fi
