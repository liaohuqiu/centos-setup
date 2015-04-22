#!/bin/bash
#
. ../base.sh

app_name=$1
# url="http://centos-files.liaohuqiu.net/f/$app_name.tar.gz"
url="https://raw.githubusercontent.com/liaohuqiu/centos-files/gh-pages/f/$app_name.tar.gz"

install_dir="/data0/install"
src_dir=$install_dir/src
downloads_dir=$install_dir/downloads

make_dir $downloads_dir;
make_dir $src_dir;

if [ ! -e $downloads_dir/$app_name.tar.gz ]; then

    exe_cmd "rm -rf $downloads_dir/$app_name.tar.gz"
    exe_cmd "cd $downloads_dir"
    exe_cmd "wget $url -P $downloads_dir"

fi

if [ ! -d $src_dir/$app_name ]; then
    exe_cmd "tar -zxvf $downloads_dir/$app_name.tar.gz -C $src_dir"
fi
exe_cmd "cd $src_dir/$app_name"
