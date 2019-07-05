export CDPATH=".:~/.shortcuts"

ulimit -n 4096

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

export PATH=$PATH:~/bin
export PATH=$PATH:~/bin/brcmutils
export PATH=$PATH:~/usr/local/opt/coreutils/libexec/gnubin

GIT_PS1_SHOWDIRTYSTATE=true
export PS1='[\e[0;32m\u@MacBook\e[m] \w\e[0;35m$(__git_ps1)\e[m\$ '

export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

export BAKE_HOME=`pwd`/bake 
export PATH=$PATH:$BAKE_HOME
export PYTHONPATH=$PYTHONPATH:$BAKE_HOME

export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
