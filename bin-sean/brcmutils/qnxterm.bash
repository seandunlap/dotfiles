#!/bin/bash

export QNX_TARGET=/tools/qnx/630/target/qnx6

export bsp_board_default=common
export bsp_os_default=qnx
export app_os_default=qnx

bsub -q atl-M16rbb -R opteron -o term.out gnome-terminal $*
