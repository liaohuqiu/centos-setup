#!/bin/bash

. ../base.sh

install_dir="/data0/install"
src_dir=$install_dir/src
downloads_dir=$install_dir/downloads

function download_src()
{
    local app_name=$1
    local file_name=$app_name".tar.gz"
    local file_path=$downloads_dir/$file_name
    local url=$2

    echo "download_src: $url => $file_path"

    make_dir $downloads_dir;
    make_dir $src_dir;

    if [[ ! -n $4 && $3 = "force" ]]; then
        exe_cmd "rm -rf $file_path"
        exe_cmd "rm -rf $src_dir/$app_name"
    fi

    if [ ! -e $file_path ]; then

        exe_cmd "cd $downloads_dir"
        exe_cmd "wget $url -P $downloads_dir"

    fi

    if [ ! -d $src_dir/$app_name ]; then
        exe_cmd "tar -zxvf $downloads_dir/$app_name.tar.gz -C $src_dir"
    fi
}

function goto_src()
{
    local app_name=$1
    exe_cmd "cd $src_dir/$app_name"
}

function parallel_make()
{
    cpunum=`cat /proc/cpuinfo |grep 'processor'|wc -l`
    make -j$cpunum
}


