#!/bin/bash
# This script takes you to the top of the CmApp/bsp directory tree.

start_directory="${PWD}"

# If this is a BFC sandbox, look for the telltale directories.
while [ "$PWD" != "/" ] ; do

   # Look for a cm_bsp_v2 directory.
   if [ -d cm_bsp_v2 ] ; then
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

# If we reached the root directory, start again and look for a .pj file.
if [[ "${PWD}" == "/" ]] ; then

   cd "$start_directory"

   # Look for a project/sandbox file.
   while [ "`echo *.pj`" == "*.pj" ] ; do
      if [[ "${PWD}" == "/" ]] ; then
         cd "$start_directory"
         break
      fi
      cd ..
   done

fi

unset start_directory

# If we didn't find a BSP directory or a project file, something's wrong.
if [ ! -d cm_bsp_v2 -a "`echo *.pj`" == "*.pj" ] ; then
   echo "Error: Couldn't find project root directory."
else
   # If a parameter was specified, see if there's a directory by that name.
   if [ "$1" != "" ] ; then
      if [ -d "$1" ] ; then
         cd $1
      else
         echo "Error: Couldn't find directory $1.  Staying at top."
      fi
   fi
fi

shift $#
