#!/bin/bash
#
. ../base.sh

if [ ! $# -eq 2 ]; then
    echo "usage: sh $0 user_name user_email"
    exit;
fi

yum -y install perl-CPAN

user_name=$1
user_email=$2
app_name="git-1.8.3.2"
url="http://centos-files.liaohuqiu.net/f/git-1.8.3.2.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"
git config --global user.name $user_name
git config --global user.email $user_email
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=86400'
