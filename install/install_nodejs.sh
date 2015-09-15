#!/bin/bash
#
. ../base.sh
app_name="node-v4.0.0"
url="http://centos-files.liaohuqiu.net/f/node-v0.12.0.tar.gz"
url="https://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
