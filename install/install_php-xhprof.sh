#!/bin/bash
#
. ../base.sh

current_dir=`pwd`

ext_name='xhprof'
file_key='php-xhprof-0.9.4'
exe_cmd "sh fetch_source.sh $file_key"

src_dir="/data0/install/src/$file_key/extension"
exe_cmd "cd $src_dir && ls -l"
exe_cmd "phpize"
exe_cmd "./configure --with-php-config=/usr/local/php/bin/php-config"
exe_cmd "make"

exe_cmd "cd $current_dir"
extension_dir="/usr/local/php/extensions"
ensure_dir $extension_dir

php_ini="/usr/local/php/etc/php.ini"
exe_cmd "cp $src_dir/modules/$ext_name.so $extension_dir"
change_line append $php_ini "extension=$ext_name.so"
