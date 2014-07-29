#!/bin/bash
#
. ../base.sh

if [ ! $# -eq 1 ]; then
    echo "usage: $0 port"
    exit 1
fi

app_name="redis-2.8.8"
url="http://centos-files.liaohuqiu.net/f/redis-2.8.8.tar.gz"
exe_cmd "sh install_simple.sh $app_name $url"

port=$1

current_dir=`pwd`
sample_config_dir=$current_dir"/config/redis"

redis_dir='/usr/local/redis'
# can not change
redis_etc_dir="$redis_dir/etc"
redis_var_dir="$redis_dir/var"
redis_data_dir="/data0/data/redis"

exe_cmd "make_dir $redis_etc_dir"
exe_cmd "make_dir $redis_var_dir"
exe_cmd "make_dir $redis_data_dir"
exe_cmd "chmod a+w $redis_data_dir"

config_file="$redis_etc_dir/redis-$port.conf"
service="redis-$port"
service_file="/etc/init.d/$service"

exe_cmd "cp $sample_config_dir/redis.conf $config_file"
exe_cmd "cp $sample_config_dir/redis_init $service_file"

exe_cmd "replace $service_file port $port"
exe_cmd "replace $config_file port $port"
exe_cmd "replace $config_file redis_data_dir $redis_data_dir"

# service: redis-$port
exe_cmd "chmod 755 /etc/init.d/$service"
exe_cmd "chkconfig --add $service"
exe_cmd "chkconfig $service on"
exe_cmd "service $service start"
