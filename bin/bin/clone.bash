#!/bin/bash

#if LOCAL_PATH does not exist, clone it
if [ ! -d rbb_cm ]; then
    echo -e "\nCloning rbb_cm from rbbsw:/projects/bfc_work1/$1"
    git clone rbbsw:/projects/bfc_work1/$1
fi

rsync -azP --filter=':- ~/.gitignore_global' rbbsw:/projects/bfc_work1/$1/rbb_cm_src ./rbb_cm_src
gtags&
