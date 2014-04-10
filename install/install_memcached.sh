#!/bin/bash
#
. ../base.sh

exe_cmd "yum install libevent-devel"
app_name="memcached-1.4.17"
url="http://centos-files.liaohuqiu.net/f/$app_name.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
