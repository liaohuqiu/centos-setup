#!/bin/bash
#
. ../base.sh

yum -y install perl-CPAN

app_name="git-1.8.3.2"
url="http://centos-files.liaohuqiu.net/f/git-1.8.3.2.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
