#!/bin/bash
#
. ../base.sh

install_dir="/data0/install"
src_dir=$install_dir/src
downloads_dir=$install_dir/downloads

url="http://nodejs.org/dist/v0.10.12/node-v0.10.12.tar.gz"
nodejs_file_name="node-v0.10.12"

make_dir $downloads_dir;
make_dir $src_dir;
exe_cmd "cd $downloads_dir"
exe_cmd "wget $url -P $downloads_dir"

exe_cmd "tar -zxvf $downloads_dir/$nodejs_file_name.tar.gz -C $src_dir"
exe_cmd "cd $src_dir/$nodejs_file_name"
exe_cmd "./configure"
exe_cmd "make && make install"
