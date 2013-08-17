#!/bin/bash
#
. ../base.sh

install_dir="/data0/install"
src_dir=$install_dir/src
downloads_dir=$install_dir/download

usr_local_lib='/usr/local/lib'
usr_local_etc='/usr/local/etc'

current_dir=`pwd`

function error_control()
{
    if [ $1 != 0 ];then
        distro=`cat /etc/issue`
        architecture=`uname -m`
        echo    "lamp errors:"
        echo "php-version:$phpv"
        echo "distributions:$distro"
        echo "architecture:$architecture"
        echo "issue:failed to install $2"
        exit 1
    fi
}

function add_user
{
    exe_cmd "groupadd $1"
    exe_cmd "useradd -s /sbin/nologin -g $1 $1"
}

function parallel_make()
{
    cpunum=`cat /proc/cpuinfo |grep 'processor'|wc -l`
    make -j$cpunum
}

function download_files()
{ 
    # enter /data0/install/downloads

    exe_cmd "cd $downloads_dir"
    local_path=$downloads_dir/$1.tar.gz;

    local file_name=$1.tar.gz
    echo "download $file_name => $local_path"
    if [ -s $local_path ]; then
        echo "$file_name [found]"
    else
        echo "$file_name [not found]"
        exe_cmd "wget http://centos.googlecode.com/files/$file_name"
        if [ ! -f $local_path ]; then
            echo "Failed to download $1, please download it to "$downloads_dir" directory manually and rerun the install script."
            exit 1
        fi
    fi

    # untar into /data0/install/src

    exe_cmd "rm -rf $src_dir/$1"
    exe_cmd "tar xzf $local_path -C $src_dir"
}

function clear_old
{
    #uninstall apache php httpd mysql
    rpm -e httpd
    rpm -e mysql
    rpm -e php

    yum -y remove httpd
    yum -y remove php
    yum -y remove mysql-server mysql
    yum -y remove php-mysql

}

function install_basic()
{
    #install some necessary tools
    if [ ! -f /tmp/yum_installed ];then
        yum -y install gcc  gcc-c++ libtool-libs autoconf freetype-devel gd libjpeg-devel  libpng-devel libxml2-devel ncurses-devel zlib-devel zip unzip curl-devel wget crontabs  file bison cmake patch mlocate flex diffutils automake make kernel-devel cpp readline-devel openssl-devel vim-minimal sendmail glibc-devel  glib2-devel bzip2-devel e2fsprogs-devel libidn-devel  gettext-devel expat-devel libcap-devel  libtool-ltdl-devel pam-devel pcre-devel libmcrypt-devel sendmail && touch /tmp/yum_installed
        code=$?
        error_control $code "necessary package,please make sure yum command can work!"
    else
        echo "necessary tools had installed,skip it!"
    fi
}

function disable_selinux()
{
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

function set_timezone()
{
    exe_cmd "rm -rf /etc/localtime"
    exe_cmd "cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
    #[ -d /proc/xen ] && echo "xen.independent_wallclock=1" >>/etc/sysctl.conf && /sbin/sysctl -p && echo "/sbin/ntpdate  cn.pool.ntp.org" >>/etc/rc.local
    yum install -y ntp
    ntpdate cn.pool.ntp.org
    ( crontab -l 2>/dev/null | grep -Fv ntpdate ; printf -- "*/3 * * * * /usr/sbin/ntpdate cn.pool.ntp.org\n" ) | crontab
}

function install_apache()
{
    apache_dir="/usr/local/apache"
    file_name="httpd-2.2.22"
    if [ ! -d $apache_dir/bin ];then

        add_user "www"
        download_files "$file_name" 

        echo "============================apache2.2 install=================================="
        echo "Start install apache2"
        cd $src_dir/$file_name

        ./configure --prefix=/usr/local/apache --with-included-apr --enable-so --enable-deflate=shared --enable-expires=shared  --enable-ssl=shared --enable-headers=shared --enable-rewrite=shared --enable-static-support 2>/root/lamp_errors.log
        code=$?
        error_control $code "$file_name"
        parallel_make 2>/root/lamp_errors.log
        code=$?
        error_control $code "$file_name"
        make install
    fi

    # register service
    exe_cmd "cp -f $current_dir/sample/apache/2.2/httpd.init /etc/init.d/httpd"
    exe_cmd "cp -f $current_dir/sample/apache/2.2/httpd.conf $apache_dir/conf"
    exe_cmd "cp -f $current_dir/sample/apache/2.2/httpd-default.conf $apache_dir/conf"

    chmod 755 /etc/init.d/httpd
    chkconfig --add httpd
    chkconfig httpd on
}

function install_mysql()
{
    mysql_install_dir="/usr/local/mysql"
    mysql_data_dir="/data0/data/mysql"
    mysqlrootpwd="root"
    mysql_file_name="mysql-5.5.24"

    if [ ! -d $mysql_install_dir ];then

        echo "============================mysql5.5 install============================================"
        if [ "$mysqlrootpwd" = "" ]; then
            mysqlrootpwd="root"
        fi	
        echo "$mysqlrootpwd" >/root/my.cnf
        echo "mysql password:$mysqlrootpwd"
        echo "####################################"

        add_user "mysql"
        download_files $mysql_file_name
        cd $src_dir/$mysql_file_name

        cmake -DCMAKE_INSTALL_PREFIX=$mysql_install_dir -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 2>/root/lamp_errors.log
        code=$?
        error_control $code $mysql_file_name
        parallel_make 2>/root/lamp_errors.log
        code=$?
        error_control $code $mysql_file_name
        make install

    else
        echo "mysql had been installed!"
    fi

    #dir
    mkdir $mysql_data_dir
    chmod +w $mysql_install_dir
    chmod +w $mysql_data_dir
    chown -R mysql:mysql $mysql_install_dir
    chown -R mysql:mysql $mysql_data_dir

    #copy config
    cd support-files/
    cp -f $current_dir/sample/conf/my5.5.cnf /etc/my.cnf
    if [ -d "/proc/vz" ];then
        sed -i "/\[mysqld\]/a \
        default-storage-engine = MyISAM\n\
        innodb=ON\n\
        skip-innodb " /etc/my.cnf
    fi
    cp -f mysql.server /etc/rc.d/init.d/mysqld
    sed -i "s:^datadir=.*:datadir=$mysql_data_dir:g" /etc/init.d/mysqld
    $mysql_install_dir/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=$mysql_data_dir --user=mysql

    chmod +x /etc/rc.d/init.d/mysqld
    chkconfig --add mysqld
    chkconfig  mysqld on

    echo "$mysql_install_dir/lib/mysql" > /etc/ld.so.conf.d/mysql.conf
    echo "$usr_local_lib" > /etc/ld.so.conf.d/mysql.conf

    ldconfig
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        ln -s $mysql_install_dir/lib/mysql /usr/lib64/mysql
    else
        ln -s $mysql_install_dir/lib/mysql /usr/lib/mysql
    fi

    ln -s $mysql_install_dir/bin/mysql /usr/bin
    ln -s $mysql_install_dir/bin/mysqladmin /usr/bin
    service mysqld start

    #Remove anonymous users
    echo "DELETE FROM mysql.user WHERE User='';" | mysql -u root 
    #Remove remote root
    echo "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';" | mysql -u root 
    #Remove test db
    echo "DROP DATABASE test;" | mysql -u root 
    #Set root password
    echo "UPDATE mysql.user SET Password=PASSWORD('$mysqlrootpwd') WHERE User='root';" | mysql -u root 
    #Flush privs
    echo "FLUSH PRIVILEGES;" | mysql -u root

    echo "============================mysql5.5 install completed=================================="
}

function install_libiconv()
{
    file_name="libiconv-1.14"
    download_files $file_name
    cd $src_dir/$file_name
    ./configure --prefix=/usr/local/libiconv 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    parallel_make 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    make install
}

function install_libmcrypt()
{
    file_name="libmcrypt-2.5.8"
    download_files "$file_name"
    cd $src_dir/$file_name
    ./configure --prefix=/usr 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    make  2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    make install
}

function install_mhash()
{
    file_name="mhash-0.9.9.9"
    download_files "$file_name"
    cd $src_dir/$file_name
    ./configure --prefix=/usr 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    parallel_make 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    make install
}

function install_mcrypt()
{
    /sbin/ldconfig
    file_name="mcrypt-2.6.8"
    download_files "$file_name"

    cd $src_dir/$file_name 
    ./configure 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    parallel_make 2>/root/lamp_errors.log
    code=$?
    error_control $code "$file_name"
    make install
}

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

function install_lib()
{
    install_libiconv
    install_libmcrypt
    install_mhash
    install_mcrypt
}

function init_env()
{
    make_dir $src_dir
    make_dir $downloads_dir
    chmod -R $src_dir
    chmod -R $downloads_dir

    exe_cmd "yum update -y"
    clear_old
    set_timezone
    install_basic
    disable_selinux
}

init_env
install_apache
install_mysql
install_lib
install_php
