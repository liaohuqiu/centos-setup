#!/bin/bash
#
. ../base.sh
export CC="gcc44"
export CXX="g++44"
app_name="libmemcached-1.0.18"
exe_cmd "sh install_simple.sh $app_name"
