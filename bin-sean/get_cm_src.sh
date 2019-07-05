#!/bin/bash

VERSION="1.7.0"

usage() {
cat <<EOF

Usage: `basename $0` [-h ] [ -b branch_name ]  [ -B branch_name ] [ -c bfc_branch ]
                         [ -r erouter_branch ] [ -x cxc_branch ] [ -s sundry_branch ]
			 [ -C common_branch ] [ -m rbb_mibs ] [ -R WiFi_branch ]
			 [ -o Bolt_branch ] [ -l Bootloader_branch ]
                         [ -w OpenWRT_branch ] [ -O repo] [ -t tag] [ -d destination_dir]

  All arguments are optional. Default settings will be used if not specified.

  NOTE: The aeolus repository will always use the "$BRANCH_AEOLUS" branch -
  even if the -b flag is used with a different branch name.

  -h: Print this message

  -b  : Specify single branch to be used for all repositories excluding WiFi
  -B  : Specify single branch to be used for all repositories including WiFi
  -d  : Specify directory (will be created) into which clone will take place
  -r : Specify erouter branch
  -w : Specify OpenWRT branch
  -R : Specify WiFi branch
  -c : Specify CM (BFC) branch
  -x: Specify CxC branch
  -l: Specify CMBLDR branch
  -s: Specify Sundry branch
  -m: Specify Sundry branch
  -C: Specify Common branch
  -o: Specify bolt branch
  -O: clone selective repositories [rbb_cm|rbb_cxc|erouter|wl]
  -t: Specify tag

  Examples:

  To checkout the default branch which is "develop" for CxC and eRouter and develop_d31 for BFC and default clone root directory
      `basename $0`

  To checkout the branch "develop" in all repositories except for "rbb_cm" and checkout "develop_d31" branch for rbb_cm
      `basename $0` -c develop_d31 -r develop -x develop -d clone_develop

  To checkout the defaut branch for respective repositories
      `basename $0` -d clone_develop

  To checkout the same branch for all repositories
      `basename $0` -b RLS_610 -d clone_RLS_610

  To checkout the code from tag for all repositories
      `basename $0` -t RLS_6.0.0.15beta2_B1 -d clone_develop

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

check_tag() {
CHK_REPO=$1
CHK_TAG=$2

( git ls-remote -t $GIT_USER@$GIT_SERVER:$CHK_REPO | grep refs/tags/$CHK_TAG )

CHK_RET=$?

if [ $CHK_RET -eq 1 ]
then
  echo -e "\n*** Error: No such tag $CHK_TAG in repo $CHK_REPO ***\n"
fi

return $CHK_RET
}

GIT_OpenWRT_USER=git://

print_pre_info() {
cat <<EOF
GIT_SERVER<$GIT_SERVER>

Cloning CM code to <$BASE_DIR>
    BFC directory:      <$CM_PATH>        Branch: <$BRANCH_CM>
    CxC directory:      <$CxC_PATH>       Branch: <$BRANCH_CxC>
    RG  directory:      <$RG_PATH>        Branch: <$BRANCH_RG>
    Kernel directory:   <$KERNEL_PATH>    Branch: <$BRANCH_KERNEL>
    Kernel 4.1 directory:   <$KERNEL_RG_PATH>    Branch: <$BRANCH_KERNEL_RG>
    OpenWRT directory:   <$OpenWRT_PATH>    Branch: <$BRANCH_OpenWRT>
    WiFi directory:   <$WIFI_PATH>    Branch: <$BRANCH_WIFI>
    WiFi_bin directory:   <$WIFI_BIN_PATH>    Branch: <$BRANCH_WIFI_BIN>
    Bolt directory:	<$BOLT_PATH>      Branch: <$BRANCH_BOLT>
    sundry directory:	<$SUNDRY_PATH>      Branch: <$BRANCH_SUNDRY>
    mibs directory:	<$MIBS_PATH>      Branch: <$BRANCH_MIBS>
    Common directory:	<$COMMON_PATH>      Branch: <$BRANCH_COMMON>

EOF
}

set_hooks() {
echo "Setting up pre-commit hooks to catch whitespace errors"


( if [[ "$REPO_CM_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$CM_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_CxC_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$CxC_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_CMBLDR_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$CMBLDR_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_RG_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$RG_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_KERNEL_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$KERNEL_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ -d "$WIFI_BIN_PATH" ]]; then
	if [[ "$REPO_WIFI_BIN_FLAG" == "Y" ]]; then
		cd $BASE_DIR/$WIFI_BIN_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
	fi
  fi
  if [[ -d "$WIFI_PATH" ]]; then
	if [[ "$REPO_WIFI_FLAG" == "Y" ]]; then
		cd $BASE_DIR/$WIFI_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
	fi
  fi
  if [[ "$REPO_BOLT_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$BOLT_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_SUNDRY_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$SUNDRY_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_MIBS_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$MIBS_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_COMMON" == "Y" ]]; then
	cd $BASE_DIR/$COMMON_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  if [[ "$REPO_BOLT_FLAG" == "Y" ]]; then
	cd $BASE_DIR/$BOLT_PATH && cp -f .git/hooks/pre-commit.sample .git/hooks/pre-commit
  fi
  ) || \
	echo -e "\n*** Error setting up pre-commit hooks - proceeding with default hooks ***"
}

T_PATH=""
do_clone() {
# Get the sources from Git
( mkdir $MAINDIR && echo && \
  if [[ "$REPO_CM_FLAG" == "Y" ]]; then
	echo "git clone -b $BRANCH_CM $GIT_USER@$GIT_SERVER:$REPO_CM $CM_PATH"
	git clone -b $BRANCH_CM $GIT_USER@$GIT_SERVER:$REPO_CM $CM_PATH && echo
	T_PATH="$CM_PATH"
  fi
  if [[ "$REPO_CxC_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_CxC $GIT_USER@$GIT_SERVER:$REPO_CxC $CxC_PATH && echo
	T_PATH="$CxC_PATH"
  fi
  if [[ "$REPO_CMBLDR_FLAG" == "Y" ]]; then
	echo "git clone -b $BRANCH_CMBLDR $GIT_USER@$GIT_SERVER:$REPO_CMBLDR $CMBLDR_PATH"
	git clone -b $BRANCH_CMBLDR $GIT_USER@$GIT_SERVER:$REPO_CMBLDR $CMBLDR_PATH && echo
	T_PATH="$CMBLDR_PATH"
  fi
  if [[ "$REPO_RG_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_RG $GIT_USER@$GIT_SERVER:$REPO_RG $RG_PATH && echo
	T_PATH="$RG_PATH"
	FIND_BRANCH_WIFI=`git ls-remote --heads  $GIT_USER@$GIT_SERVER:$REPO_WIFI_BIN | grep refs | cut -f3 -d "/"  | grep $BRANCH_RG`
	if [[ "$BRANCH_RG" == "$FIND_BRANCH_WIFI" ]]; then
		echo "Found corresponding branch in WiFi repo."
		CLONE_WIFI_BIN="Y"
		if [[ "$BRANCH_RG" == *5.8.0* ]]; then
			REPO_OpenWRT_FLAG="N"
		fi
	else
		REPO_OpenWRT_FLAG="N"
	fi
	if [[ "$BRANCH_RG" == "$FIND_BRANCH_KERNEL_RG" ]]; then
		echo "Found corresponding branch in rglinux repo."
		KERNEL_PATH=$RG_PATH/linux-3.14
		CLONE_KERNEL_RG="Y"
		REPO_KERNEL_RG_FLAG="Y";
	fi
  fi
  if [[ "$REPO_KERNEL_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_KERNEL $GIT_USER@$GIT_SERVER:$REPO_KERNEL $KERNEL_PATH && echo
	T_PATH="$KERNEL_PATH"
  fi
  if [[ "$REPO_KERNEL_RG_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_KERNEL_RG $GIT_USER@$GIT_SERVER:$REPO_KERNEL_RG $KERNEL_RG_PATH && echo
	T_PATH="$KERNEL_RG_PATH"
	REPO_KERNEL_RG_FLAG="Y";
  fi
  if [[ "$REPO_OpenWRT_FLAG" == "Y" ]]; then
	echo "git clone -b $BRANCH_OpenWRT $GIT_OpenWRT_USER$GIT_OpenWRT_SERVER/$REPO_OpenWRT $OpenWRT_PATH"
	git clone -b $BRANCH_OpenWRT $GIT_OpenWRT_USER$GIT_OpenWRT_SERVER/$REPO_OpenWRT $OpenWRT_PATH && echo
	T_PATH="$OpenWRT_PATH"
  fi
  if [[ ! -d "$WIFI_PATH" ]]; then
	if [[ "$REPO_WIFI_FLAG" == "Y" ]]; then
		git clone -b $BRANCH_WIFI $GIT_USER@$GIT_SERVER:$REPO_WIFI $WIFI_PATH && echo
		T_PATH="$WIFI_PATH"
		CLONE_WIFI_BIN="Y"
	fi
  fi
  if [[ "$CLONE_WIFI_BIN" == "Y" ]]; then
     if [[ ! -d "$WIFI_BIN_PATH" ]]; then
	if [[ "$REPO_WIFI_BIN_FLAG" == "Y" ]]; then
		echo "Cloning.."
		git clone -b $BRANCH_WIFI_BIN $GIT_USER@$GIT_SERVER:$REPO_WIFI_BIN $WIFI_BIN_PATH && echo
		T_PATH="$WIFI_BIN_PATH"
	fi
     fi
  fi
  if [[ "$REPO_SUNDRY_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_SUNDRY $GIT_USER@$GIT_SERVER:$REPO_SUNDRY $SUNDRY_PATH && echo
	T_PATH="$SUNDRY_PATH"
  fi
  if [[ "$REPO_MIBS_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_MIBS $GIT_USER@$GIT_SERVER:$REPO_MIBS $MIBS_PATH && echo
	T_PATH="$MIBS_PATH"
  fi
  if [[ "$REPO_COMMON_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_COMMON $GIT_USER@$GIT_SERVER:$REPO_COMMON $COMMON_PATH && echo
	T_PATH="$COMMON_PATH"
	COMMON_MAKEFILE=${COMMON_PATH}/Makefile
	if [ -f $COMMON__MAKEFILE ]; then
		cd $MAINDIR
		ln -s rbb_common/Makefile Makefile
		cd ..
		pwd
	fi
  fi
  if [[ "$REPO_BOLT_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_BOLT $GIT_USER@$GIT_SERVER:$REPO_BOLT $BOLT_PATH && echo
	T_PATH="$BOLT_PATH"
  fi
  cd $BASE_DIR/$T_PATH && git remote -v && \
  return 0 ) || return 1
}

do_clone_ro() {
GIT_USER=git://

# Get the sources from Git
( mkdir $MAINDIR && echo && \
  if [[ "REPO_CM_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_CM $GIT_USER$GIT_SERVER/$REPO_CM $CM_PATH && echo
  fi
  if [[ "REPO_CxC_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_ROOTFS $GIT_USER$GIT_SERVER/$REPO_CxC $CxC_PATH && echo
  fi
  if [[ "REPO_CMBLDR_FLAG" == "Y" ]]; then
	echo "git clone -b $BRANCH_ROOTFS $GIT_USER$GIT_SERVER/$REPO_CMBLDR $CMBLDR_PATH"
	git clone -b $BRANCH_ROOTFS $GIT_USER$GIT_SERVER/$REPO_CMBLDR $CMBLDR_PATH && echo
  fi
  if [[ "REPO_RG_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_RG $GIT_USER$GIT_SERVER/$REPO_RG $RG_PATH && echo
  fi
  if [[ "REPO_KERNEL_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_KERNEL $GIT_USER$GIT_SERVER/$REPO_KERNEL $KERNEL_PATH && echo
  fi
  if [[ "REPO_KERNEL_RG_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_KERNEL_RG $GIT_USER$GIT_SERVER/$REPO_KERNEL_RG $KERNEL_PATH_RG && echo
  fi
  if [[ "REPO_OpenWRT_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_OpenWRT $GIT_OpenWRT_USER$GIT_OpenWRT_SERVER\/$REPO_OpenWRT $OpenWRT_PATH && echo
  fi
  if [[ "REPO_WIFI_BIN_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_WIFI_BIN $GIT_USER$GIT_SERVER/$REPO_WIFI_BIN $WIFI_BIN_PATH && echo
  fi
  if [[ "REPO_WIFI_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_WIFI $GIT_USER$GIT_SERVER/$REPO_WIFI $WIFI_PATH && echo
  fi
  if [[ "REPO_SUNDRY_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_SUNDRY $GIT_USER$GIT_SERVER/$REPO_SUNDRY $SUNDRY_PATH && echo
  fi
  if [[ "REPO_MIBS_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_MIBS $GIT_USER$GIT_SERVER/$REPO_MIBS $MIBS_PATH && echo
  fi
  if [[ "REPO_COMMON_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_COMMON $GIT_USER$GIT_SERVER/$REPO_COMMON $COMMON_PATH && echo
  fi
  if [[ "REPO_BOLT_FLAG" == "Y" ]]; then
	git clone -b $BRANCH_BOLT $GIT_USER$GIT_SERVER/$REPO_BOLT $BOLT_PATH && echo
  fi
  cd $BASE_DIR/$CM_PATH && git remote -v && \
  return 0 ) || return 1
}

#
# Begin script execution
#

BRANCH_CM=develop_d31
BRANCH_CxC=develop
BRANCH_RG=develop
BRANCH_KERNEL=develop
BRANCH_KERNEL_RG=develop
BRANCH_OpenWRT=brcmstb-15.05.1
BRANCH_WIFI=$BRANCH_RG
BRANCH_WIFI_BIN=$BRANCH_RG
BRANCH_BOLT=master
BRANCH_SUNDRY=master
BRANCH_MIBS=master
BRANCH_COMMON=develop
BRANCH_CMBLDR=CmBootloader270

GIT_USER=gitcmand

if [[ "$SITE" == "" ]]; then
	SITE=`hostname | cut -f2 -d"-"`
fi

if [[ "$SITE" == "" ]]; then
	GIT_SERVER=git-atl-01.atl.broadcom.com
else
	GIT_SERVER=git-${SITE}-01.${SITE}.broadcom.com
fi
if [[ "$SITE" == "ric" ]]; then
	GIT_SERVER=git-ric-1.ric.broadcom.com
fi
if [[ "$SITE" == "and" ]]; then
	GIT_SERVER=git-and-02.and.broadcom.com
fi
if [[ "$SITE" == "irv" ]]; then
	GIT_SERVER=git-irv-08.irv.broadcom.com
fi
if [[ "$SITE" != "atl" && "$SITE" != "and"  && "$SITE" != "ric" && "$SITE" != "irv" ]]; then
	GIT_SERVER=git-atl-01.atl.broadcom.com
fi
GIT_OpenWRT_SERVER=stbgit.broadcom.com

REPO_CM=gitRepo/rbb_cm.git
REPO_CxC=gitRepo/rbb_cxc.git
REPO_RG=gitRepo/erouter.git
REPO_CMBLDR=gitRepo/rbb_cm_bootloader.git
REPO_KERNEL=gitRepo/erouter-linux-314.git
REPO_KERNEL_RG=gitRepo/rglinux.git
REPO_OpenWRT=queue/openwrt.git
REPO_WIFI=gitRepo/rbb_wifi.git
REPO_WIFI_BIN=gitRepo/rbb_wifi_bin.git
REPO_BOLT=gitRepo/rbb_cm_bolt.git
REPO_SUNDRY=gitRepo/rbb_sundry.git
REPO_MIBS=gitRepo/rbb_mibs.git
REPO_COMMON=gitRepo/rbb_common.git

#REPO_LIST="$REPO_CM $REPO_CxC $REPO_RG $REPO_KERNEL $REPO_WIFI $REPO_WIFI_BIN"
#REPO_LIST="$REPO_CM $REPO_CxC $REPO_RG $REPO_KERNEL $REPO_WIFI_BIN"
REPO_LIST="$REPO_CM $REPO_CxC $REPO_RG $REPO_KERNEL"

CLONE_RO=0

#MAINDIR="CM_${BRANCH_CM}_clone_${USER}"
echo -e "\neRouter clone script version: $VERSION\n"
echo "Default branch:      $BRANCH_CM $BRANCH_RG"
echo -e "Default directory:   $MAINDIR\n"
echo "GIT_SERVER-${GIT_SERVER}"

while getopts ":c:C:b:d:h:O:t:l:w:x:R:r:s:m:S:o:B:" opt; do
  case $opt in
      c)
        echo "Setting bfc branch: $OPTARG"
        check_branch $REPO_CM $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_CM=$OPTARG
        ;;
      S)
	SITE=$OPTARG
	echo "Setting site to: $SITE"
	;;
      s)
        echo "Setting sundry branch: $OPTARG"
        check_branch $REPO_SUNDRY $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_SUNDRY=$OPTARG
        ;;
      m)
        echo "Setting sundry branch: $OPTARG"
        check_branch $REPO_MIBS $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_MIBS=$OPTARG
        ;;
      C)
        echo "Setting common branch: $OPTARG"
        check_branch $REPO_COMMON $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_COMMON=$OPTARG
        ;;
      o)
        echo "Setting bolt branch: $OPTARG"
        check_branch $REPO_BOLT $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_BOLT=$OPTARG
        ;;
      b)
        echo "Setting all branch: $OPTARG"
	if [ "$MAINDIR" == "" ]; then
		MAINDIR="CM_${OPTARG}_clone_${USER}"
	fi
        B_RET=0
        for i in $REPO_LIST; do
          check_branch $i $OPTARG
          B_RET+=$?
        done
        if [ $B_RET -ne 0 ]
        then
          exit $B_RET
        else
          BRANCH_CM=$OPTARG
          BRANCH_CxC=$OPTARG
          BRANCH_RG=$OPTARG
          BRANCH_KERNEL=$OPTARG
          BRANCH_KERNEL_RG=$OPTARG
#          BRANCH_WIFI_BIN=$OPTARG
          BRANCH_COMMON=$OPTARG
        fi
        ;;
      B)
        echo "Setting all branch: $OPTARG"
	if [ "$MAINDIR" == "" ]; then
		MAINDIR="CM_${OPTARG}_clone_${USER}"
	fi
        B_RET=0
        for i in $REPO_LIST; do
          check_branch $i $OPTARG
          B_RET+=$?
        done
        if [ $B_RET -ne 0 ]
        then
          exit $B_RET
        else
          BRANCH_CM=$OPTARG
          BRANCH_CxC=$OPTARG
          BRANCH_RG=$OPTARG
          BRANCH_KERNEL=$OPTARG
          BRANCH_KERNEL_RG=$OPTARG
          BRANCH_WIFI_BIN=$OPTARG
          BRANCH_WIFI=$OPTARG
          BRANCH_COMMON=$OPTARG
        fi
	REPO_WIFI_FLAG="Y"
        ;;
      d)
        echo "Setting base directory: $OPTARG"
        MAINDIR=$OPTARG
        ;;
      h)
        usage
        exit 0
        ;;
      t)
        echo "Setting tag: $OPTARG"
        TAG=$OPTARG
        echo "Setting all tags: $OPTARG"
	if [ "$MAINDIR" == "" ]; then
		MAINDIR="CM_${OPTARG}_clone_${USER}"
	fi
        B_RET=0
        for i in $REPO_LIST; do
	  echo "REPOS-$REPOS"
          check_tag $i $OPTARG
          B_RET+=$?
        done
        if [ $B_RET -ne 0 ]
        then
          exit $B_RET
        else
          BRANCH_CM=$OPTARG
          BRANCH_CxC=$OPTARG
          BRANCH_RG=$OPTARG
          BRANCH_KERNEL=$OPTARG
          BRANCH_KERNEL_RG=$OPTARG
          BRANCH_WIFI=$OPTARG
          BRANCH_WIFI_BIN=$OPTARG
          BRANCH_COMMON=$OPTARG
        fi
	;;
      x)
        echo "Setting rbb_cxc branch: $OPTARG"
        check_branch $REPO_CxC $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_CxC=$OPTARG
        ;;
      w)
        echo "Setting OpenWRT branch: $OPTARG"
#       check_branch $REPO_OpenWRT $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_OpenWRT=$OPTARG
        ;;
      l)
        echo "Setting rbb_cm_bootloader branch: $OPTARG"
        check_branch $REPO_CMBLDR $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_CMBLDR=$OPTARG
	MAINDIR="CM_${OPTARG}_clone_${USER}"
        ;;
      r)
        echo "Setting erouter branch: $OPTARG"
        check_branch $REPO_RG $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_RG=$OPTARG
        echo "Setting linux branch: $OPTARG"
        check_branch $REPO_KERNEL $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_KERNEL=$OPTARG
        BRANCH_KERNEL_RG=$OPTARG
        BRANCH_WIFI=$OPTARG
        BRANCH_WIFI_BIN=$OPTARG
        ;;
      R)
        echo "Setting erouter branch: $OPTARG"
        check_branch $REPO_RG $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_RG=$OPTARG
        echo "Setting linux branch: $OPTARG"
        check_branch $REPO_KERNEL $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_KERNEL=$OPTARG
        BRANCH_KERNEL_RG=$OPTARG
        echo "Setting WiFi branch: $OPTARG"
        check_branch $REPO_WIFI $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        check_branch $REPO_WIFI_BIN $OPTARG
        if [ $? -eq 1 ]
        then
          exit 1
        fi
        BRANCH_WIFI=$OPTARG
        BRANCH_WIFI_BIN=$OPTARG
	REPO_WIFI_FLAG="Y"
        ;;
      O)
        echo "Setting list of repos: $OPTARG"
        REPOS=$OPTARG
	space=" "
	if [ "$REPOS" != "" ]; then
		REPO_ARY="${REPOS/,/$space}"
		REPO_ARY="${REPO_ARY/rbb_cm/gitRepo/rbb_cm.git}"
		REPO_ARY="${REPO_ARY/rbb_cxc/gitRepo/rbb_cxc.git}"
		REPO_ARY="${REPO_ARY/erouter/gitRepo/erouter.git gitRepo/erouter-linux-314.git}"
		REPO_ARY="${REPO_ARY/wl/gitRepo/erouter.git gitRepo/erouter-linux-314.git gitRepo/rbb_wifi.git gitRepo/rbb_wifi_bin.git}"
		REPO_LIST="${REPO_ARY}"
	fi
	echo "REPO_LIST-$REPO_LIST"
	;;
      :)
        echo "Option \"$OPTARG\" requires an argument"
        exit 1
        ;;
      *)
        echo "$OPTARG"
        echo "Unimplemented option chosen"
        exit 1
        ;;   # Default
  esac
done

if [[ "$SITE" == "" ]]; then
	SITE=`hostname | cut -f2 -d"-"`
fi

if [[ "$SITE" == "" ]]; then
	GIT_SERVER=git-atl-01.atl.broadcom.com
else
	GIT_SERVER=git-${SITE}-01.${SITE}.broadcom.com
fi
if [[ "$SITE" == "ric" ]]; then
	GIT_SERVER=git-ric-1.ric.broadcom.com
fi
if [[ "$SITE" == "and" ]]; then
	GIT_SERVER=git-and-02.and.broadcom.com
fi
if [[ "$SITE" == "irv" ]]; then
	GIT_SERVER=git-irv-08.irv.broadcom.com
fi
if [[ "$SITE" != "atl" && "$SITE" != "and"  && "$SITE" != "ric" && "$SITE" != "irv" ]]; then
	GIT_SERVER=git-atl-01.atl.broadcom.com
fi
GIT_OpenWRT_SERVER=stbgit.broadcom.com

if [[ "$MAINDIR" == "" ]]; then
	MAINDIR="CM_${BRANCH_CM}_clone_${USER}"
fi

FIND_BRANCH_KERNEL_RG=`git ls-remote --heads  $GIT_USER@$GIT_SERVER:$REPO_KERNEL_RG | grep refs | cut -f3 -d "/"  | grep $BRANCH_RG`

CM_DIRNAME=rbb_cm
CM_PATH=$MAINDIR/$CM_DIRNAME

CxC_DIRNAME=rbb_cxc
CxC_PATH=$MAINDIR/$CxC_DIRNAME

CMBLDR_DIRNAME=rbb_cm_bootloader
CMBLDR_PATH=$MAINDIR/$CMBLDR_DIRNAME

RG_DIRNAME=erouter
RG_PATH=$MAINDIR/$RG_DIRNAME

KERNEL_DIRNAME=linux
if [[ "$FIND_BRANCH_KERNEL_RG" != "" ]]; then
	KERNEL_DIRNAME=linux-3.14
fi
KERNEL_PATH=$RG_PATH/$KERNEL_DIRNAME

KERNEL_RG_DIRNAME=linux-4.1
KERNEL_RG_PATH=$RG_PATH/$KERNEL_RG_DIRNAME

OpenWRT_DIRNAME=openwrt
OpenWRT_PATH=$MAINDIR/$OpenWRT_DIRNAME

WIFI_DIRNAME=rg_apps/bcmdrivers/broadcom/net/wl
WIFI_PATH=$RG_PATH/$WIFI_DIRNAME

WIFI_BIN_DIRNAME=rg_apps/bcmdrivers/broadcom/net/wl_bin
WIFI_BIN_PATH=$RG_PATH/$WIFI_BIN_DIRNAME/

SUNDRY_DIRNAME=rbb_sundry
SUNDRY_PATH=$MAINDIR/$SUNDRY_DIRNAME

COMMON_DIRNAME=rbb_common
COMMON_PATH=$MAINDIR/$COMMON_DIRNAME

MIBS_DIRNAME=rbb_mibs
MIBS_PATH=$MAINDIR/$MIBS_DIRNAME

BOLT_DIRNAME=bolt
BOLT_PATH=$MAINDIR/$BOLT_DIRNAME

if [[ "$MAINDIR" == /* ]]; then
	BASE_DIR=""
else
	BASE_DIR=`pwd`
fi

print_pre_info

if [[ "$REPOS" == "" ]]; then
	REPO_CM_FLAG="Y"
	REPO_CxC_FLAG="Y"
	REPO_RG_FLAG="Y"
	REPO_KERNEL_FLAG="Y"
	REPO_OpenWRT_FLAG="Y"
	REPO_WIFI_BIN_FLAG="Y"
#	REPO_WIFI_FLAG="Y"
	REPO_SUNDRY_FLAG="Y";
	REPO_MIBS_FLAG="Y";
	REPO_COMMON_FLAG="Y";
	REPO_BOLT_FLAG="Y";
	REPO_CMBLDR_FLAG="Y";
fi
if [[ "$REPOS" == *rbb_cm* ]]; then
	if [[ "$REPOS" != *bootloader* ]]; then
		REPO_CM_FLAG="Y"
	fi
fi
if [[ "$REPOS" == *rbb_cxc* ]]; then
	REPO_CxC_FLAG="Y"
fi
if [[ "$REPOS" == *rbb_cm_bootloader* ]]; then
	REPO_CMBLDR_FLAG="Y"
fi
if [[ "$REPOS" == *erouter* ]]; then
	REPO_RG_FLAG="Y"
	REPO_KERNEL_FLAG="Y"
	REPO_WIFI_BIN_FLAG="Y"
fi
if [[ "$REPOS" == *wl* ]]; then
	REPO_RG_FLAG="Y"
	REPO_KERNEL_FLAG="Y"
	REPO_WIFI_BIN_FLAG="Y"
	REPO_WIFI_FLAG="Y"
fi
if [[ "$REPOS" == *sundry* ]]; then
	REPO_SUNDRY_FLAG="Y"
fi
if [[ "$REPOS" == *mibs* ]]; then
	REPO_MIBS_FLAG="Y"
fi
if [[ "$REPOS" == *common* ]]; then
	REPO_COMMON_FLAG="Y"
fi
if [[ "$REPOS" == *openwrt* ]]; then
	REPO_OpenWRT_FLAG="Y"
fi
if [[ "$REPOS" == *bolt* ]]; then
	REPO_BOLT_FLAG="Y"
fi
if [[ "$REPOS" == *linux* ]]; then
	REPO_KERNEL_FLAG="Y"
	REPO_RG_FLAG="Y"
fi

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
else
  echo -e "\n*** Error cloning git repository ***\n"
  exit 1
fi
