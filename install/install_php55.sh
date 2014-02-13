#!/bin/bash

. ./install_base.sh

#todo
#php pear
#php pecl

current_dir=`pwd`
app=php-5.5.9
url=http://centos-files.liaohuqiu.net/f/php-5.5.9.tar.gz
env="dev"                           # dev/prod

php_path=/usr/local/php
apach_path=/usr/local/apache/bin/apxs

php_config_path=$php_path/etc
sample_config_dir=$current_dir"/config/php"

ensure_dir $php_path
ensure_dir $php_config_path
ensure_dir $php_config_path/php.d

function install_basic()
{
    #todo:  make clear what the dependency
    #apt-get install -y build-essential autoconf libmemcached-dev curl imagemagick libmagickwand-dev libevent-dev libtool libxml2-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libmcrypt-dev libxslt1-dev sendmail zlib1g-dev

    yum -y install gcc gcc-c++ libtool-libs autoconf freetype-devel gd libjpeg-devel  libpng-devel libxml2-devel ncurses-devel zlib-devel zip unzip curl-devel wget crontabs  file bison cmake patch mlocate flex diffutils automake make kernel-devel cpp readline-devel openssl-devel vim-minimal sendmail glibc-devel  glib2-devel bzip2-devel e2fsprogs-devel libidn-devel  gettext-devel expat-devel libcap-devel libtool-ltdl-devel pam-devel pcre-devel libmcrypt-devel sendmail libxslt-devel
}

function do_install()
{

    #http://php.net/manual/en/configure.about.php

    #--enable-fpm                       进程管理器。nginx需要
    #--enable-bcmath                    高精度数学。float加减乘除比大小需要。
    #--with-curl                        curl。用于http请求。
    #--with-mcrypt                      加密。
    #--enable-mbstring                  多字节字符串。用于处理unicode字符。
    #--with-pdo-mysql                   PDO封装mysql。PHP官方推荐使用。
    #--with-mysqli                      封装mysql。用于mysql 5+。PHP官方推荐使用。
    #--with-mysql                       封装mysql。用于mysql 4。PHP官方不推荐使用。
    #--with-openssl                     stmp https发信时需要。
    #--with-imap-ssl                    imap https收信时需要。
    #--with-gd                          常用的图形库。
    #--with-jpeg-dir                    调用系统的libjpeg。
    #--with-png-dir                     调用系统的libpng。
    #--enable-exif                      开启exif。压缩图片时要根据方向orientation进行旋转。
    #--enable-zip                       开启zip。
    #--with-zlib                        pear 打包要用。
    #--with-xsl                         phpdoc2 要用。
    #--with-apxs2                       apach mod_php
    #--with-config-file-path            $php_config_path
    #--with-config-file-scan-dir        $php_config_path/php.d
    #--enable-ftp 
    #--with-freetype-dir
    #--enable-gd-native-ttf
    #--with-iconv=/usr/local/libiconv
    #--with-mysql=/usr/local/mysql 
    #--without-pear

    configure_cmd="--prefix=$php_path --enable-fpm --enable-bcmath --with-curl --with-mcrypt --enable-mbstring --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql --with-openssl --with-imap-ssl --with-gd --with-jpeg-dir=/usr/lib/ --with-png-dir=/usr/lib/ --enable-exif --enable-zip --with-zlib --with-apxs2=$apach_path --with-config-file-path=$php_config_path --with-config-file-scan-dir=$php_config_path/php.d --enable-ftp  --with-freetype-dir --enable-gd-native-ttf --with-iconv=/usr/local/libiconv --with-mysql=/usr/local/mysql --without-pear"

    if [ $env = 'dev' ]; then
        configure_cmd="$configure_cmd --with-xsl"
    fi

    exe_cmd "./configure $configure_cmd"

    parallel_make 2>/root/lamp_errors.log
    exe_cmd "make install"
}

function make_easy_use()
{
    if [ $env = 'prod' ]; then
        exe_cmd "cp $sample_config_dir/php.ini-production $php_config_path/php.ini"
    else
        exe_cmd "cp $sample_config_dir/php.ini-development $php_config_path/php.ini"
    fi
    rm -rf $php_config_path/php.d/*

    ln -sf $php_path/bin/php /usr/bin/php
    ln -sf $php_path/bin/phpize /usr/bin/phpize
    ln -sf $php_path/bin/php-config /usr/bin/php-config

    exe_cmd "cp $sample_config_dir/php-fpm.conf $php_config_path/php-fpm.conf"
    exe_cmd "cp $sample_config_dir/init.d.php-fpm /etc/init.d/php-fpm"

    chkconfig php-fpm on
    chmod u+x /etc/init.d/php-fpm
    service php-fpm start

}

install_basic
download_src $app $url
goto_src $app

do_install
make_easy_use
