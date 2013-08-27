#!/bin/bash
#
. ../base.sh

current_dir=`pwd`
mysql_path="/usr/local/mysql"

mysqldata="/data0/data/mysql"
install_dir="/data0/install"
untar_path=$install_dir/untar
mysqlrootpwd="root"
prj_physical_dir='/data0/prj'
prj_dir='/prj'
usr_local_lib='/usr/local/lib'
usr_local_etc='/usr/local/etc'

function install_proftpd()
{
    proftpd_path="/usr/local/proftpd"
    proftpd_conf_path=/usr/local/etc/proftpd.conf
    proftpd_auth_user_file="/usr/local/etc/proftpd_auth_user"
    if [ ! -d $proftpd_path ]; then

        cd $install_path
        wget ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.4c.tar.gz 
        tar -xvf proftpd-1.3.4c.tar.gz
        cd proftpd-1.3.4c
        ./configure --prefix=$proftpd_path
        make && make install
    fi

    cp $current_dir/sample/conf/proftpd.init /etc/init.d/proftpd
    chmod 755 /etc/init.d/proftpd
    chkconfig --add proftpd
    chkconfig proftpd on

    ln -sf $proftpd_path/sbin/proftpd /usr/sbin/proftpd

    cp $current_dir/sample/conf/proftpd.conf $proftpd_conf_path
    echo "AuthUserFile $proftpd_auth_user_file" >> $proftpd_conf_path

    #create default user
    www_uid=`id -u www`
    www_gid=`id -g www`
    echo "srain" | $proftpd_path/bin/ftpasswd --passwd --name=www --uid=$www_uid --gid=$www_gid --home=/prj/ --shell=/sbin/nologin --file=$proftpd_auth_user_file --stdin

    service proftpd restart
}

