#!/bin/bash
# This script takes you to the top of the CmApp/bsp directory tree, up one
# directory, and back down into another root directory.

start_directory="${PWD}"

# If this is a BFC sandbox, look for the BSP directory
while [ "$PWD" != "/" ] ; do

   # Look for a cm_bsp_v2 directory.
   if [ -d cm_bsp_v2 ] ; then
      break
   fi

   cd ..

done


# If we reached the root directory, start again and look for a .pj file.
if [ "${PWD}" == "/" ] ; then
   cd "$start_directory"

   # Look for a project/sandbox file.
   while [ "`echo *.pj`" == "*.pj" ] ; do
      if [ "${PWD}" == "/" ] ; then
         cd "$start_directory"
         break
      fi
      cd ..
   done

fi

# If we didn't find a BSP directory or a project file, something's wrong.
# Or maybe there's a sibling just one level up...
if [ ! -d cm_bsp_v2 -a "`echo *.pj`" == "*.pj" ] ; then
   if [ -e ../$1 ] ; then
      "cd" ../$1
   elif [ -e ./$1 ] ; then
      "cd" ./$1
   else
      echo "Error: Couldn't find project root directory."
      cd "$start_directory"
   fi
else
   cd ..
   # If a parameter was specified, see if there's a directory by that name.
   if [ "$1" != "" ] ; then
      set $1
      if [ -d $1 ] ; then
         "cd" $1
      else
         echo "Error: Couldn't find the sibling project directory $1"
         "cd" "$start_directory"
      fi
   fi
fi

# Look for known parent directories.
#for d in rbb_cm_src bfc_systems_v4 bfc_systems ; do
#   if [ -d $d ] ; then
#      cd ..
#      break
#   fi
#done

shift $#
unset start_directory
