#!/bin/bash

. ../base.sh

ext_name=$1
file_key=$2

extension_dir="/usr/local/php/extensions"
ensure_dir $extension_dir

php_ini="/usr/local/php/etc/php.ini"
src_dir="/data0/install/src/$file_key"
exe_cmd "cp $src_dir/modules/$ext_name.so $extension_dir"
change_line append $php_ini "extension=$ext_name.so"
