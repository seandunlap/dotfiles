#!/bin/bash

declare -a branches=("develop_d31" "Prod_6.1.0" "Prod_6.1.1" "Prod_6.1.2")

git log $branches > union.txt
cat union.txt > output.txt

# compute difference between per stream commits and all commits
for stream in "${stream_list[@]}"
do
    comm union.txt $stream.txt \
        | sed 's/^SWCM-[0-9]*//g' \
        | sed -e 's/^[[:space:]]*//'
        > tmp1

    # concatinate this branch results into next column of table
    paste output.txt tmp1 \
        | pr -t -e15 > tmp2
    cat tmp2 > output.txt
done

# reverse the sort order so newest SWCMs show up first
cat output.txt | sort -r > tmp
cat tmp > output.txt
cat output.txt

# curl -u sdunlap:Kellymae6 jira.broadcom.com/rest/api/latest/issue/SWCM-46735 | python -c "import json,sys;obj=json.load(sys.stdin);print obj['self'];"

# curl -u sdunlap:Kellymae6 jira.broadcom.com/rest/api/latest/issue/SWCM-46735 | python -c "import json,sys;obj=json.load(sys.stdin);print obj['name'];"

# https://answers.atlassian.com/questions/58265/get-parent-issue-via-rest-or-soap-api-clients

# $Array.fields.issuetype.subtask and look for a TRUE value...and it's a subtask.
# $Array.fields.parent.key holds the parent issue.

curl -D- -u sdunlap:Kellymae6 -X GET -H "Content-Type: application/json" 'http://jira.broadcom.com/rest/api/2/search?jql=projectKey=CMSW+order+by+duedate&fields=id,key'
# curl -s http://twitter.com/users/username.json | python -c "import json,sys;obj=json.load(sys.stdin);print obj['name'];"