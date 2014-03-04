#!/bin/bash
#
. ../base.sh

app_name="ruby-2.0.0-p451"
url="http://centos-files.liaohuqiu.net/f/ruby-2.0.0-p451.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
