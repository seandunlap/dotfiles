#!/bin/bash
# This shell script is designed to be used as a "dot" command, so it does some
# odd things like returning instead of exiting, and "shift $#" to get rid of
# the positional parameters for the next execution before each "return".

shopt -s extglob

function give_help {
  echo
  echo "This script changes the default directory into the specified build"
  echo "(target) directory and executes a command.  If no parameters are given,"
  echo "goes to the most recent build directory."
  echo
  echo "Usage: tdx [board [option]] command"
  echo
  echo "Parameters:"
  echo "    board  - board number (3345, 3350, 3351, 3352, or 3360)"
  echo "             May be abbreviated to 45, 50, 51, 52, 60."
  echo "    option - major build option (propane, vendor, cablehome, slim, or none)"
  echo "             May be abbreviated to one or two characters."
  echo
  echo "Examples:"
  echo "    tdx 50 p ls        - goes to ./bcm93350_propane"
  echo "    tdx 3345 slim ls   - goes to ./bcm93345_slim"
  echo "    tdx 3360 vendor ls - goes to ./bcm93360_vendor"
  echo "    tdx ls             - goes to ./bcm93360_vendor"
  echo "    tdx 51 p ls        - goes to ./bcm93351_propane"
  echo "    tdx 45 s ls        - goes to ./bcm93345_slim"
}

td_board=$old_td_board
td_option=$old_td_option

while [ "$1" != "" ] ; do
   case ${1} in
      "?"|"-?"|help|-help)
         give_help
         shift $#
         unset td_option
         unset td_board
         unset give_help
         return
         ;;
      45|48|49|50|51|52|60)
         td_board="bcm933${1}"
         shift
         ;;
      33@(45|48|49|50|51|52|60))
         td_board="bcm9${1}"
         shift
         ;;
      p*(r|ropane))
         td_option="_propane"
         shift
         ;;
      s*(l|lim))
         td_option="_slim"
         shift
         ;;
      v*(e|endor))
         td_option="_vendor"
         shift
         ;;
      c*(a|ablehome))
         td_option="_cablehome"
         shift
         ;;
      n*(o|one))
         td_option=""
         shift
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
         break
         ;;
   esac
done

if [ "${td_board}" != "" ] ; then
   if [ -d ${td_board}${td_option} ] ; then
      td_dir=${td_board}${td_option}
   else
      echo "Error: Directory ${td_board}${td_option} not found."
      shift $#
      unset td_option
      unset td_board
      unset give_help
      return
   fi
fi

cd ${td_dir}

echo "In ${td_dir} executing:" $*
eval $*

cd ..

shift $#

old_td_board=$td_board
old_td_option=$td_option

unset td_option
unset td_board
unset give_help
