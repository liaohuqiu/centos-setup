#!/bin/bash

. ../base.sh
. ../config.sh

current_dir=`pwd`

ext_name='sockets'

file_key=$php_ver_dir'-sockets'
source_src_dir="/data0/install/src/$php_ver_dir/ext/sockets"

source_dir="/data0/install/src/$file_key"
exe_cmd "rm -rf $source_dir"
exe_cmd "cp -rf $source_src_dir $source_dir"

exe_cmd "cd $source_dir && ls -l"
exe_cmd "phpize"
exe_cmd "./configure --with-php-config=/usr/local/php/bin/php-config"
exe_cmd "make"

exe_cmd "cd $current_dir"
exe_cmd "sh install_php_ext.sh $ext_name $file_key"
