#!/bin/bash

if [ "$1" == "" ] ; then
    cd /projects/bfc/work/$USER
elif [ -d /projects/bfc/work/$1 ] ; then
    cd /projects/bfc/work/$1
else
    cd /projects/bfc/work/$USER
    dir=`eval echo $1`
    if [ -d "$dir" ] ; then
        cd $dir
    else
        echo "Error: $dir doesn't exist in your work directory"
    fi
fi
