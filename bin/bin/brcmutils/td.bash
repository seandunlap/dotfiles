#!/bin/bash
# This shell script is designed to be used as a "dot" command, so it does some
# odd things like returning instead of exiting, and "shift $#" to get rid of
# the positional parameters for the next execution before each "return".
function give_help {
  echo
  echo "This script changes the default directory into the specified build"
  echo "(target) directory.  If no parameters are given, goes to the most"
  echo "recent build directory."
  echo
  echo "Usage: td [board [option]]"
  echo
  echo "Parameters:"
  echo "    board  - board number (3349, 3368, 5365, 3255, etc.)"
  echo "             33xx chip IDs may be abbreviated to the last two digits"
  echo "    option - major build option (eu or slim)"
  echo "             May be abbreviated."
  echo
  echo "Examples:"
  echo "    td 50 p        goes to ./bcm93350_propane"
  echo "    td 3345 slim   goes to ./bcm93345_slim"
  echo "    td 3360 vendor goes to ./bcm93360_vendor"
  echo "    td             goes to ./bcm93360_vendor"
  echo "    td 51 p        goes to ./bcm93351_propane"
  echo "    td 45 s        goes to ./bcm93345_slim"
}

td_board=$old_td_board
td_option=$old_td_option
td_extension=$old_td_extension

while [ "$1" != "" ] ; do
   case ${1} in
      "?"|"-?"|help|-help)
         give_help
         shift $#
         unset td_option
         unset td_board
         unset td_extension
         unset give_help
         return
         ;;
      45|48|49|50|51|52|60|68|80|81)
         td_board="bcm933${1}"
         ;;
      33@(45|48|49|50|51|52|60|68)|5365|3255)
         td_board="bcm9${1}"
         ;;
      cm)
         td_extension="cmvendor"
         ;;
      e*ps)
         td_extension="eps"
         ;;
      p*(r|ropane))
         td_option="_propane"
         ;;
      f*at)
         td_option=""
         ;;
      s*(l|lim))
         td_option="_slim"
         ;;
      v*(e|endor))
         td_option="_vendor"
         ;;
      c*(a|ablehome))
         td_option="_cablehome"
         ;;
      l*(a|at|ate|ates|atest))
         # Find the latest build directory, and remove the trailing "/".
         td_dir=`ls -td bcm9*`
         td_dir=${td_dir%/}
         td_board=
         ;;
      *)
         if [ -d ${1} ] ; then
            td_board=$1
            shift
            continue
         fi
         for d in ${1}_* ; do
            if [ -d $d ] ; then
               td_board=$1
               shift
               continue 2
            fi
         done
         echo "Error: Invalid parameter ${1}"
         shift $#
         unset td_option
         unset td_board
         unset give_help
         return
         ;;
   esac
   shift
done


if [ "${td_board}" != "" ] ; then
   newdir="${td_board}${td_extension}${td_option}"
   if [ -e $newdir ] ; then
      td_dir=$newdir
   else
      echo "Error: Directory $newdir not found."
      shift $#
      unset td_option
      unset td_board
      unset newdir
      unset give_help
      return
   fi
fi

if [ "$td_dir" == "" ] ; then
   td_dir=`ls -td bcm9* 2>/dev/null| head -1`
fi
if [ "$td_dir" != "" ] ; then
   cd ${td_dir}
fi

old_td_board=$td_board
old_td_option=$td_option
old_td_extension=$td_extension

shift $#
unset td_option
unset td_board
unset td_extension
unset newdir
unset give_help
