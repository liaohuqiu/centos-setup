http://wiki.bash-hackers.org/howto/getopts_tutorial
http://unix.stackexchange.com/questions/50563/how-can-i-detect-that-no-options-were-passed-with-getopts

#!/bin/bash
help="Usage: $0 [-s signal]

Options:
-h            : this help
-s signal     : send signal to a master process: start, stop, reload(restart)
"
s="start"

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
    echo '正在启动'
    /php/sbin/php-fpm
    echo '已启动'
    ;;
    "stop" )
    echo '正在关闭'
    kill -INT `cat /php/var/run/php-fpm.pid`
    echo '已关闭'
    ;;
    "restart"|"reload" )
    echo '正在重启'
    kill -USR2 `cat /php/var/run/php-fpm.pid`
    echo '已重启'
    ;;
esac
