#!/bin/bash
#
. ../base.sh

path="http://mirrors.163.com/.help/CentOS6-Base-163.repo"
exe_cmd "cd /etc/yum.repos.d/"
exe_cmd "mv CentOS-Base.repo CentOS-Base.repo.backup"
exe_cmd "wget $path"
exe_cmd "mv CentOS6-Base-163.repo CentOS-Base.repo"
exe_cmd "yum makecache"

#yum -y install yum-fastestmirror
