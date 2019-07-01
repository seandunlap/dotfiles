#!/bin/bash

if [ ! -d /tmp/$USER ] ; then
    mkdir /tmp/$USER
fi

#. root.bash

echo $PWD
projdir=${PWD##*/}
dest=/tmp/$USER/$projdir
if [ ! -d $dest ] ; then
    mkdir $dest
fi

rm -rf $dest/*

# Link in the top-level directories, except rbb_cm_src and cablex
for d in * ; do
    if [ $d == rbb_cm_src ] ; then
        continue
    fi
    if [ $d == cablex ] ; then
        continue
    fi
    ln -s $PWD/$d $dest/$d
done

# Copy cablex in its entirety
cp -pr cablex $dest/

if true ; then
    # Copy CmDocsisSystem in its entirety.
    cp -pr rbb_cm_src $dest/
else
    # Link in most rbb_cm_src directories, except CmDocsisSystem
    mkdir  $dest/rbb_cm_src
    cd rbb_cm_src
    for d in * ; do
        if [ $d == CmDocsisSystem ] ; then
            continue
        fi
        ln -s $PWD/$d $dest/rbb_cm_src/$d
    done

    # Copy CmDocsisSystem in its entirety.
    cp -pr CmDocsisSystem $dest/rbb_cm_src
fi
