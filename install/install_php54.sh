#!/bin/bash

. ./install_base.sh

app=php-5.4.18
url=http://www.php.net/get/php-5.4.18.tar.gz/from/this/mirror
download_src $app $url
goto_src $app

function install_php()
{
    file_name="php-5.2.17"
    if [ ! -d /usr/local/php ];then
        #install PHP5.2

        download_files "$file_name"
        echo "============================PHP5.2 install============================================"
        #as php5.2 only search libs in /usr/lib/,we must ajust it.
        if [ ! -f "/usr/lib/libjpeg.so" ];then
            cp "`find /usr -name libjpeg.so|head -1`" /usr/lib/
            cp "`find /usr -name libpng.so|head -1`" /usr/lib/
        fi
        cd $install_dir/
        cp -f $current_dir/sample/conf/php-5.2.17-max-input-vars.patch $src_dir/$file_name/
        cd $src_dir/$file_name
        patch -p1 < php-5.2.17-max-input-vars.patch
        ./configure --prefix=/usr/local/php  --with-apxs2=/usr/local/apache/bin/apxs --enable-discard-path --with-config-file-path=$usr_local_etc --with-config-file-scan-dir=$usr_local_etc/php.d --with-openssl --with-zlib  --with-curl --enable-ftp  --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf  --enable-mbstring --with-mcrypt --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=/usr/local/mysql --without-pear 2>/root/lamp_errors.log
        code=$?
        error_control $code
        parallel_make 2>/root/lamp_errors.log
        code=$?
        error_control $code
        make install
        cp -f $current_dir/sample/conf/php5.2.ini $usr_local_etc/php.ini
        mkdir $usr_local_etc/php.d
        rm -rf $usr_local_etc/php.d/*

        ln -s /usr/local/php/bin/php /usr/bin/php
        ln -s /usr/local/php/bin/phpize /usr/bin/phpize
        ln -s /usr/local/php/bin/php-config /usr/bin/phpize-config

        echo "============================PHP5.2 install completed============================================"
    else
        echo "PHP had been installed"
    fi
}

