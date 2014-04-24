#!/bin/sh
pid=`cat /usr/local/php/var/run/php-fpm.pid`
kill $pid
/usr/local/php/sbin/php-fpm
