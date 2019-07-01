#!/bin/bash

shopt -s extglob

#set -a

# Only add the bin dir to the path the first time through.  This keeps the path
# from getting cluttered.
if [ "${PATH/mipsisa32-elf\/bin/}" == "$PATH" ] ; then
   export PATH="/tools/ecos/3.2.1_opt/Linux/opt/ecos/gnutools/mipsisa32-elf/bin:$PATH"
fi

if [ "$USER" == "" -a "$LOGNAME" != "" ] ; then
   export USER=$LOGNAME
fi

alias ls="ls -F"
alias sd="cd"
alias path='echo $PATH'

alias bsp=". bsp.bash"
alias app=". app.bash"
alias top=". top.bash"
alias up=". up.bash"
alias root=". root.bash"
alias td=". td.bash"
alias tdx=". tdx.bash"
alias work="cd /projects/bfc/work/$USER"

PS1='\u@\h \w\n$ '

# Only add these directories to the path if they exist, and they are not
# already in the path.
ADDED_PATHS="/tools/brcmutils"

for dir in $ADDED_PATHS ; do
   if [ -d $dir ] ; then
      if [ `echo ":$PATH:" | grep -c :$dir:` == 0 ] ; then
         PATH="$PATH:$dir"
      fi
   fi
done


# Here's where we used to find ProgramStore and MessageLogZapper.
#if [ -d /usr/local/brcmutils ] ; then
#   PATH="$PATH:/usr/local/brcmutils"
#fi

# ECOS_DIR is the root directory for the eCos installation - including the
# Gnu tools.  It should only be necessary when building the eCos library.
export ECOS_DIR="/projects/bfc/ecos20"

# ECOS_CONFIG_ROOT is the root directory for the eCos configurations, include
# files, and libraries.
export ECOS_CONFIG_ROOT=${ECOS_DIR}

# ECOS_CONFIG_DIR is the active eCos configuration directory.
export ECOS_CONFIG_DIR="bcm33xx/bcm33xx_install"

# Make sure we don't inherit this variable from a VxWorks configuration.
unset GCC_EXEC_PREFIX

export CXC_COMPILER_ROOT_DIR=/tools/ecos/3.2.1_opt/Linux/opt/ecos/gnutools/mipsisa32-elf

export app_os_default=ecos
export bsp_os_default=ecos
export bsp_board_default=common

# This is where we get the code for 3380fpga I/O processors.
export BBP_DIR=/projects/bfc/bbp/shared/sim
