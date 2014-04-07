#!/bin/bash
#
. ../base.sh

PATH=$PATH:/usr/sbin
export PATH

install_dir="/data0/install"
src_dir=$install_dir/src
downloads_dir=$install_dir/downloads

make_dir $src_dir
make_dir $downloads_dir

usr_local_lib='/usr/local/lib'
usr_local_etc='/usr/local/etc'

current_dir=`pwd`

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
        exe_cmd "wget http://centos-files.liaohuqiu.net/f/$file_name"
        if [ ! -f $local_path ]; then
            echo "Failed to download $1, please download it to "$downloads_dir" directory manually and rerun the install script."
            exit 1
        fi
    fi

    # untar into /data0/install/src

    exe_cmd "rm -rf $src_dir/$1"
    exe_cmd "tar xzf $local_path -C $src_dir"
}

function install_basic()
{
    #install some necessary tools
    if [ ! -f /tmp/yum_installed ];then
        yum -y install gcc  gcc-c++ libtool-libs autoconf freetype-devel gd libjpeg-devel  libpng-devel libxml2-devel ncurses-devel zlib-devel zip unzip curl-devel wget crontabs  file bison cmake patch mlocate flex diffutils automake make kernel-devel cpp readline-devel openssl-devel vim-minimal sendmail glibc-devel  glib2-devel bzip2-devel e2fsprogs-devel libidn-devel  gettext-devel expat-devel libcap-devel  libtool-ltdl-devel pam-devel pcre-devel libmcrypt-devel sendmail && touch /tmp/yum_installed
        code=$?
    else
        echo "necessary tools had installed,skip it!"
    fi
}

function install_mysql()
{
    mysql_install_dir="/usr/local/mysql"
    mysql_data_dir="/data0/data/mysql"
    mysqlrootpwd="root"
    mysql_file_name="mysql-5.5.24"

    add_user "mysql"
    if [ ! -d $mysql_install_dir ];then

        echo "============================mysql5.5 install============================================"
        if [ "$mysqlrootpwd" = "" ]; then
            mysqlrootpwd="root"
        fi	
        echo "$mysqlrootpwd" >/root/my.cnf
        echo "mysql password:$mysqlrootpwd"
        echo "####################################"

        download_files $mysql_file_name
        exe_cmd "cd $src_dir/$mysql_file_name"

        cmake -DCMAKE_INSTALL_PREFIX=$mysql_install_dir -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1
        parallel_make 2>/root/lamp_errors.log
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
    cd $src_dir/$mysql_file_name/support-files/
    cp -f $current_dir/sample/conf/my5.5.cnf /etc/my.cnf
    if [ -d "/proc/vz" ];then
        sed -i "/\[mysqld\]/a \
        default-storage-engine = MyISAM\n\
        innodb=ON\n\
        skip-innodb " /etc/my.cnf
    fi
    cp -f mysql.server /etc/rc.d/init.d/mysqld
    sed -i "s:^datadir=.*:datadir=$mysql_data_dir:g" /etc/init.d/mysqld
    exe_cmd "$mysql_install_dir/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=$mysql_data_dir --user=mysql"

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
    /etc/init.d/mysqld start

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

install_mysql
