#!/bin/bash

. ../base.sh

current_dir=`pwd`

ext_name='yar'
file_key='yar-1.2.4'
exe_cmd "sh fetch_source.sh $file_key https://pecl.php.net/get/yar-1.2.4.tgz"

src_dir="/data0/install/src/$file_key"
exe_cmd "cd $src_dir && ls -l"
exe_cmd "phpize"
exe_cmd "./configure --with-php-config=/usr/local/php/bin/php-config --disable-memcached-sasl"
exe_cmd "make"

exe_cmd "cd $current_dir"
exe_cmd "sh install_php_ext.sh $ext_name $file_key"
