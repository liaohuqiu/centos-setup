#!/bin/bash

function make_dir()
{
    if [ ! -d $1 ]; then
        exe_cmd "mkdir -p $1"
    fi
}
function link_dir()
{
    if [ -e $2 ];then
        exe_cmd "rm $2"
        exe_cmd "ln -sf $1 $2"
    fi
}

function exe_cmd()
{
    echo $1
    eval $1
}

# key, cmd
function crontab_add()
{
    local key=$1
    local cmd=$2
    ( crontab -l 2>/dev/null | grep -Fv $key ; printf -- "$cmd\n" ) | crontab
}
current_dir=`pwd`
apache_dir="/usr/local/apache"
str_sp='+++++++++++++++++++++++++++++++++++++++++++++'
