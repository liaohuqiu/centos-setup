#!/bin/bash
#
. ../base.sh
sudo yum install -y gcc44 gcc-c++
sudo yum install -y gcc44-c++.x86_64
export CC="gcc44"
export CXX="g++44"
app_name="libmemcached-1.0.18"
exe_cmd "sh install_simple.sh $app_name"
