#!/bin/bash

# Only add these directories to the path if they exist, and they are not
# already in the path.
ADDED_PATHS="\
             /tools/accurev/bin \
             /projects/rbbswbld/AccuRev/triggers/linux \
             /usr/local/bin \
             /tools/bin \
             . \
             /home/$USER/commands \
             /usr/atria/bin \
             /bin"

for dir in $ADDED_PATHS ; do
   if [ -d $dir ] ; then
      if [ `echo ":$PATH:" | grep -c :$dir:` == 0 ] ; then
         PATH="$dir:$PATH"
      fi
   fi
done

if [ -e /tools/brcmutils/ecos.bash ] ; then
   source /tools/brcmutils/ecos.bash
fi

alias objdump="mipsisa32-elf-objdump"

# This script may run from a telnet session, which means DISPLAY
# won't bet set.
if [ "$DISPLAY" == "" -a "$TERM" != "dumb" ] ; then
    # If I telnet'ed in, my info includes my PC's DHCP address in parentheses.
    # There are two possible formats:
    #   (dhcp-10-24-64-80)
    #   (10.24.65.27)
    t=`who am i`
    # If there are no parentheses, there's nothing to do.
    if [ "${t/(/}" != "$t" ] ; then
        # First extract only what's in parentheses.
        t=${t#*\(}
        t=${t%\)*}
        if [ "${t:0:5}" == "dhcp-" ] ; then
            # Remove the leading "dhcp-".
            t=${t/dhcp-/}
            # Remove a possible trailing ".broadcom...".
            t=${t%%.*}
        fi
        # Change all "-" characters to ".".
        t=${t//-/.}
        export DISPLAY=$t:0.0
    fi
fi

# This is here for AccuRev
export LC_ALL=en_US.utf8
export BASHVER=4.2

export CCACHE_DISABLE=1
