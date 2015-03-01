#!/bin/bash
#
. ../base.sh
app_name="node-v0.12.0"
url="http://centos-files.liaohuqiu.net/f/node-v0.12.0.tar.gz"
url="https://raw.githubusercontent.com/liaohuqiu/centos-files/gh-pages/f/node-v0.12.0.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
