#!/bin/bash

shopt -s extglob

# This shell script is designed to be used as a "dot" command, so it does some
# odd things like returning instead of exiting, and "shift $#" to get rid of
# the positional parameters for the next execution before each "return".
function give_help {
  echo
  echo "This script goes up the directory tree to the root and back down to the bsp"
  echo "tree.  If os or board is omitted, it defaults to the previous usage.  If \"def\""
  echo "is specified, it resets both board and os."
  echo
  echo "Usage: BSP [board [os] [def]]"
  echo
  echo "Parameters:"
  echo "    board - chip ID (3345, 3348, 3340, etc.), common or top"
  echo "            May be abbreviated to 45, 48, 50, 51, 52, 60, c, or t."
  echo "    os    - operating system (psos, vxworks, linux, ecos, qnx, or top)"
  echo "            May be abbreviated to one or more characters."
  echo "    def   - Make the current settings the defaults.  Abbreviate as d."
  echo
  echo "Examples:"
  echo "    bsp 50 vx        goes to <root>/cm_bsp_v2/bsp_bcm93350/os/vxworks"
  echo "    bsp 3345 psos d  goes to <root>/cm_bsp_v2/bsp_bcm93345/os/psos"
  echo "    bsp 3360         goes to <root>/cm_bsp_v2/bsp_bcm93360/os/psos"
  echo "    bsp              goes to <root>/cm_bsp_v2/bsp_bcm93345/os/psos"
  echo "    bsp 50 top       goes to <root>/cm_bsp_v2/bsp_bcm93350"
  echo "    bsp top          goes to <root>/cm_bsp_v2"
}

bsp_board=""
bsp_os=$bsp_os_default

# Look for the BSP project root directory.
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

   # Look for known parent directories.
   for d in rbb_cm_src bfc_systems_v4 bfc_systems ; do
      if [ -d $d ] ; then
         cd $d
         break 2
      fi
   done

   cd ..

done

if [[ "${PWD}" == "/" ]] ; then

   cd "$start_directory"

fi

unset start_directory

# If we found the root directory, go there.  Otherwise bail.
if [ -d CableModemBsp/bsp_common ] ; then
   cd CableModemBsp
elif [ -d cm_bsp_v2/bsp_common ] ; then
   cd cm_bsp_v2
else
   echo "Error: BSP root directory cm_bsp_v2 not found."
   shift $#
   unset give_help
   unset bsp_os
   unset bsp_board
   return
fi

# Parse all the parameters...
while [ "$1" != "" ] ; do
   case ${1} in
      "?"|"-?"|help|-help|--help)
         give_help
         shift $#
         unset give_help
         unset bsp_os
         unset bsp_board
         return
         ;;
      45|48|50|51|52|60)
         bsp_board="bcm933${1}"
         ;;
      33@(45|48|50|51|52|60))
         bsp_board="bcm9${1}"
         ;;
      c*(o|om|omm|ommo|ommon))
         bsp_board="common"
         ;;
      t*(o|op))
         if [ "$bsp_board" = "" ] ; then
            bsp_board=top
         fi
         unset bsp_os
         ;;
      p*(s|so|sos))
         bsp_os=psos
         ;;
      v*(x|xw|xwo|xwor|xwork|xworks))
         bsp_os=vxworks
         ;;
      l*(i|in|inu|inux))
         bsp_os=linux
         ;;
      e*(c|co|cos))
         bsp_os=ecos
         ;;
      q*(n|nx))
         bsp_os=qnx
         ;;
      d*(e|ef))
         bsp_os_default=$bsp_os
         bsp_board_default=$bsp_board
         ;;
      *)
         if [ -d bsp_bcm9${1} ] ; then
            bsp_board=bcm9${1}
         elif [ -d bsp_bcm933${1} ] ; then
            bsp_board=bcm933${1}
         else
            echo "Error: Invalid parameter ${1}"
            shift $#
            unset give_help
            unset bsp_os
            unset bsp_board
            return
         fi
         ;;
   esac
   shift
done

if [ "$bsp_board" = "" ] ; then
   bsp_board=$bsp_board_default
fi

if [ "$bsp_board" = "top" ] ; then
   unset bsp_board
fi


if [ "${bsp_board}" == "" ] ; then
   shift $#
   unset give_help
   unset bsp_os
   unset bsp_board
   return
fi

if [ $bsp_board == bcm93351 ] ; then
   if [ ! -d bsp_bcm93351 ] ; then
      echo "There's no bsp for a 3351.  Going to 3352 bsp."
      bsp_board=bcm93352
   fi
fi

if [ -d bsp_${bsp_board} ] ; then
   cd bsp_${bsp_board}
else
   echo "Error: BSP directory bsp_${bsp_board} not found."
   shift $#
   unset give_help
   unset bsp_os
   unset bsp_board
   return
fi

if [ "${bsp_os}" == "" ] ; then
   shift $#
   unset give_help
   unset bsp_os
   unset bsp_board
   return
fi

if [ -d os/${bsp_os} ] ; then
   cd os/${bsp_os}
else
   echo "Error: OS directory os/${bsp_os} not found."
fi

shift $#
unset bsp_os
unset bsp_board
unset give_help
