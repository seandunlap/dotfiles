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

alias lld="cd ~/workspace/rbb_cm/rbb_cm_src/CableModemBsp/bsp_common/CmHal/LowLatencyDocsis && cmake . && make && ./myapp" 

alias ws='open -n /Applications/Wireshark.app'
alias s='ssh rbbsw'
alias get_nightly="rsync -azP sdunlap@lc-atl-344.ash.broadcom.net:/projects/rbbswbld-store/images/nightly/Prod_6.1.0-D31/2016-11-11 ~/Drive"
#alias find_in_prog="find . -type d -name rbb_cm -exec bash -c echo "\n===> In directory {}; cd {}; git status;" \;"
alias zip-modified-files='git diff --name-only HEAD | xargs tar cvf $1'
alias pwn='scp -v -i ~/.ssh/puma-key-pair.pem /Library/WebServer/Documents/a.php ec2-user@54.245.199.106:/var/www/html'
alias app=". app.bash"
alias makeapp="~/bin/makeapp.bash"
alias cm="screen /dev/tty.usbserial-00302414C 115200"
alias rg="screen /dev/tty.usbserial-00302414D 115200"
alias tty="lsof | grep usbserial"
alias tty2="screen -x <process id>"
alias cliff="ssh cd901063@cliffd-MacBook"
alias tftp_server='sudo launchctl load -F /System/Library/LaunchDaemons/tftp.plist & sudo launchctl start com.apple.tftpd'
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
