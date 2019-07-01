#!/bin/bash
#
# This script starts with an rbb_cm clone from the current directory,
# makes another clone of it, and from this new clone, filters out
# all of the files and folders in the skip-list that we do not
# distribute to the customer.  This filtering completely re-writes
# the history - it is not just an exclusion list for a zip file.
#
# It uses a popular and widely used package called BFG Repo Cleaner
# to do the filtering.  It is 10-720x faster than the traditional
# git-filter-branch method.

# abort on any error
set -e

cd $REPO_NAME
pwd
git clean -fd

# remove all branches except the BRANCH_NAME
git reflog expire --expire=now refs/heads/$CURRENT_BRANCH
git gc --prune=now --aggressive
git fsck --unreachable
git prune
git gc

#   # compute set of folders not matching the directories found in the load rules list
#   #cat $(find . -type f -name 'load_rules.txt') > load_rules
#   #find . -type d | cut -f2 > folders
#
#   # find the skiplist file and split it's contents into a list of files and a list of folders
rm ../files
rm ../folders

cat $(find . -type f -name '*skip_list.txt') | cut -c 3- | grep -E '[*.]' | grep -v '*' | rev | cut -d'/' -f 1 | rev | sort | uniq > ../files
echo "Skip-list files:"
cat ../files
cat $(find . -type f -name '*skip_list.txt') | cut -c 3- | grep -vE '[*.]' | grep -v '*' | rev | cut -d'/' -f 1 | rev | sort | uniq > ../folders
echo "Skip-list folders:"
cat ../folders


bfg --no-blob-protection --delete-folders rbb_cm_lib
bfg --no-blob-protection --delete-folders rbb_win32_lib
bfg --no-blob-protection --delete-folders Win32TestApps

while read -r name; do
bfg --no-blob-protection --delete-folders $name;
done < ../folders

while read -r name; do
bfg --no-blob-protection --delete-files "$name";
done < ../files

git reflog expire --expire=now --all && git gc --prune=now --aggressive
