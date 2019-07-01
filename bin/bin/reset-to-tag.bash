#!/bin/bash

set -x

export BRANCH_FROM_TAG=refs/tags/RLS_Prod_6.1.1mp1beta3_B1
export BRANCH_FROM_BRANCH=$(git branch --contains $BRANCH_FROM_TAG)
export CUSTOMER_BRANCH_NAME=Prod_6.1.1mp1_Netgear

git checkout Prod_6.1.1
git branch -D Prod_6.1.1mp1
git branch -D Prod_6.1.1mp1_Netgear
git branch -D Prod_6.1.2mp1
git branch -D temp

git checkout -b Prod_6.1.1mp1 refs/tags/RLS_Prod_6.1.1mp1beta3_B1
git checkout -b Prod_6.1.1mp1_Netgear
git checkout -b Prod_6.1.2mp1 refs/tags/RLS_Prod_6.1.2mp1_B1
git checkout -b temp
git merge -s ours -m "Make Prod_6.1.1mp1_Netgear branch identical to the Prod_6.1.2mp1 release" Prod_6.1.1mp1_Netgear
git checkout Prod_6.1.1mp1_Netgear
git merge temp


git diff --name-only HEAD | sort | uniq > modified_files.txt
cat rbb_cm_src/BrcmUtils/CfgRls/release_skip_list.txt | sort | uniq > blacklisted_files.txt

cat files_to_patch.txt | xargs -L 1 -I{} tar cvf patch.tgz {}


git diff --name-only HEAD | sort | uniq > modified_files.txt

git filter-branch --subdirectory-filter foodir -- --all
cat rbb_cm_src/BrcmUtils/CfgRls/release_skip_list.txt | cut -c 3- | sort | uniq | grep -vE '[*.]'

grep -v "\." skiplist.txt > skiplist
grep "\." skiplist_files.txt

