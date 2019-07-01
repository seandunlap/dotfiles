#!/bin/bash

set -x

export BRANCH_NAME=refs/tags/RLS_Prod_6.1.1mp1beta3_B1
export BRANCH_FROM_BRANCH=$(git branch --contains $BRANCH_FROM_TAG)
export CUSTOMER_BRANCH_NAME=Prod_6.1.1mp1_Netgear

git diff --name-only HEAD | sort | uniq > modified_files.txt
cat rbb_cm_src/BrcmUtils/CfgRls/release_skip_list.txt | sort | uniq > blacklisted_files.txt
cat files_to_patch.txt | xargs -L 1 -I{} tar cvf patch.tgz {}
git merge-base --fork-point HEAD
cat rbb_cm_src/BrcmUtils/CfgRls/release_skip_list.txt | cut -c 3- | sort | uniq > skiplist.txt

grep -v "\." skiplist.txt > skiplist_folders.txt
grep "\." skiplist.txt > skiplist_files.txt
git checkout -b $BRANCH_NAME-TEMP
git diff --name-only HEAD | sort | uniq > modified_files.txt

diff -u <(git rev-list --first-parent topic) <(git rev-list --first-parent master) | sed -ne 's/^ //p' | head -1