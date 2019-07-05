#!/bin/bash

case "$1" in
   [1-9])
      let i=1
      while [ $i -le $1 ] ; do
         cd ..
         let i=i+1
      done
      ;;
   "")
      cd ..
      ;;
   -?|?|-help|help)
      echo "This script goes up a number of directories in the tree.  You must"
      echo "specify a number from 1 to 9"
      ;;
   *)
      echo "ERROR: Number must be from 1-9."
      ;;
esac

shift $#
