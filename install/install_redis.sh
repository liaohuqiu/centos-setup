#!/bin/bash
#
. ../base.sh

app_name="redis-2.8.8"
url="http://centos-files.liaohuqiu.net/f/redis-2.8.8.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
