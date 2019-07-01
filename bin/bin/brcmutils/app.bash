#!/bin/bash

# This shell script is designed to be used as a "dot" command, so it does some
# odd things like returning instead of exiting, and "shift $#" to get rid of
# the positional parameters for the next execution before each "return".

function give_help {
   echo
   echo "This script goes up the directory tree to the root and back down to the CmApp"
   echo "tree.  If os is omitted, it defaults to the previous setting.  If \"def\" is"
   echo "specified, it changes the default setting."
   echo
   echo "Usage: app [os] [def]"
   echo
   echo "Parameters:"
   echo "    os    - CmApp operating system (psos, vxworks, ecos, qnx, linux, or top)"
   echo "    def   - Changes default OS dir."
   echo "            Parameters may be abbreviated to one or two characters."
   echo
   echo "Examples:"
   echo "    app vx      goes to <root>/CmDocsisSystem/vxWorks"
   echo "    app ecos d  goes to <root>/CmDocsisSystem/ecos and changes default"
   echo "    app         goes to <root>/CmDocsisSystem/ecos"
   echo "    app top     goes to <root>/CmDocsisSystem"
}

function error {
   echo "Error: $*"
   shift $#
   unset give_help
}

app_name=""
shopt -s extglob

start_directory="${PWD}"

# If this is a BFC sandbox, look for the telltale directories.
while [ "$PWD" != "/" ] ; do

   # Look for a cm_bsp_v2 directory.
   if [ -d cm_bsp_v2 ] ; then
      break
   fi

   # Look for a CableModemBsp directory.
   if [ -d CableModemBsp ] ; then
      break
   fi

   # Look for GIT top folder.
   if [ -d rbb_cm ] ; then
      cd rbb_cm/rbb_cm_src
      break
   fi

   # Look for known parent directories.
   for d in rbb_cm_src bfc_systems_v4 bfc_systems ; do
      if [ -d $d ] ; then
         cd $d
         break 2
      fi
   done

   cd ..

done


# If we reached the root directory, pick default of ~/workspace
if [[ "${PWD}" == "/" ]] ; then
   cd ~/workspace/rbb_cm
fi

unset start_directory


if [ "${app_name}" != "" ] ; then

   shopt -q nocaseglob
   nocase_status=$?
   shopt -s nocaseglob
   app_dir=""
   if [ -d ${app_name}/${app_os} ] ; then
      app_dir=$app_name
   else
      for f in ${app_name}* ; do
         if [ -d $f/${app_os} ] ; then
            app_dir=$f
            break
         fi
      done
   fi
   if [ $nocase_status == 1 ] ; then
      shopt -u nocaseglob
   fi
   if [ "$app_dir" == "" ] ; then
      error "App directory ${app_name}*/${app_os} not found."
      return
   fi
   cd $app_dir

elif [ -d CmApp_Docsis1.0 ] ; then

   cd CmApp_Docsis1.0

elif [ -d CmBootloader/app ] ; then

   cd CmBootloader/app
   unset app_os

elif [ -d app ] ; then

   cd app
   unset app_os

else

   error "APP root directory not found."
   return

fi

if [ "${app_os}" != "" ] ; then

   if [ -d ~/workspace/rbb_cm${app_os} ] ; then
      cd $app_os
   else
      error "OS directory ${app_os} not found."
   fi

fi


shift $#
unset app_os
unset give_help
