http://wiki.bash-hackers.org/howto/getopts_tutorial
http://unix.stackexchange.com/questions/50563/how-can-i-detect-that-no-options-were-passed-with-getopts

#!/bin/bash
help="Usage: $0 [-s signal]

Options:
-h            : this help
-s signal     : send signal to a master process: start, stop, reload(restart)
"
s="start"

pid_file=/home/admin/fpm-php/var/run/php-fpm.pid
php_ini=/home/admin/fpm-php/lib/php.ini
php_fpm_conf=/home/admin/fpm-php/etc/php-fpm.conf
php_fpm=/home/admin/fpm-php/sbin/php-fpm

function exe_cmd() 
{
    echo $1
    eval $1
}

while getopts s:h opt
do
    case $opt in
        "s" )
        eval $opt=$OPTARG
        ;;
        *)
        echo "$help"
        exit
        ;;
    esac
done
echo 'php-fpm'
case $s in
    "start" )
    echo 'start'
    exe_cmd "$php_fpm_conf -c=$php_ini -g=$pid_file -y=$php_fpm_conf"
    ;;
    "stop" )
    echo "stop"
    exe_cmd "kill -INT `cat $pid_file`"
    ;;
    "restart"|"reload" )
    echo "reload"
    exe_cmd "kill -USR2 `cat $pid_file`"
    ;;
esac
