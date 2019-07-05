#!/bin/sh
NAME="git-jira"
VERSION=0.0.1
DESCRIPTION='Show git tags containing commits for the specified JIRA'
LICENSE='Report bugs, feature requests to Sean Dunlap'
USAGE='git missing <source-branch> <dest-branch>'

# Exit immediately upon failure, and command printing for reference
set -e

# uncomment to enable script debugging
#set -x

# Self-identify, ignoring a useless $0 in git alias invocations
case "$1" in --version|version) echo $VERSION >&2 ; exit 64 ;; esac
CMD="$0"
if { printf %s "$CMD" | grep [[:space:]] && ! command -v "$CMD"; } >/dev/null 2>&1 ; then CMD=; fi

# usage [<error message> [<exit code>]]
usage () {
        # TTY output gets a bolded name and underlined URL
        if [ -t 2 ]; then
                ansify='{ sub(/[^/]+$/, "\x1b[1m&\x1b[22m"); if(/[/]/) $0="\x1b[4m" $0 "\x1b[0m"; print }'
                NAME="`echo $NAME | awk "$ansify"`"
        fi

        message="$1"
        if [ "z$1" = z ]; then message="`printf '%s %s\n%s' "$NAME" "$VERSION" "$DESCRIPTION"`"; fi
        printf '%s\n\nUsage: %s %s\n\n%s\n' "$message" "$CMD" "$USAGE" "$LICENSE" | sed 's/\\//g' >&2

        if [ "z$2" != z ]; then exit $2; fi
        exit 64
}

main () {
    echo "Commits in $1 that need to be merged to $2"
    git log --cherry-pick --left-only origin/$1...$2 --oneline --format='%h %an' | grep -v Gurpreet | cut -d ' ' -f 1 | xargs -I {} -n1 git log -1 --pretty=format:'%s' > $1-to-$2.txt
    cat $1-to-$2.txt
}

# Normal mode relies on script arguments
if [ "z$CMD" != z ]; then main "$@"; exit; fi

# git alias mode uses the appended arguments
main
