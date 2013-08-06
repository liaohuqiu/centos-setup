#!/bin/bash
helpOnline="在线安装（默认）：$0"
help="离线安装: $0 -i offline"

i='online'
while getopts i:h opt
do
    case $opt in
    "i" )
        eval $opt=$OPTARG
        ;;
    *)
        echo $helpOnline
        echo $help
        exit
        ;;
    esac
done

if [ $i != 'offline' ]; then
    i=online
fi

echo '---------lnmp一键安装--------
项目地址：http://code.taobao.org/p/lnmp/src/

已测试支持以下系统：
Ubuntu Server 12.04.2 LTS 64-bit
Ubuntu Desktop 13.04 64-bit

建议使用没有管理员权限的普通用户进行安装、运行，更安全。
为nginx、php、mysql建立普通用户lnmp

安装步骤：
1、管理员进行准备

安装依赖库
Ubuntu使用如下命令：
sudo apt-get install -y build-essential autoconf libmemcached-dev curl imagemagick libmagickwand-dev libevent-dev libtool libxml2-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libmcrypt-dev libxslt1-dev sendmail zlib1g-dev

CentOS使用如下命令：
todo

然后无论是Ubuntu还是CentOS，都要建立普通用户
sudo useradd -m -s /bin/bash lnmp
sudo passwd lnmp

2、普通用户安装nginx和php
su lnmp
cd ~
#脚本下载地址： http://code.taobao.org/svn/lnmp/trunk/src/lnmp.sh
#脚本下载地址短网址： http://dwz.cn/lnmp-sh
wget http://dwz.cn/lnmp-sh
chmod +x lnmp-sh
./lnmp-sh
'

echo '已完成第1步？开始安装（y）或取消（n）'
read goon
if [ $goon != 'y' ]; then
    exit 0
fi

echo '生产环境（prod） 还是 开发环境（dev）？'
read env
if [ $env != 'prod' ]; then
    env=dev
fi

downloadDir=$HOME/Downloads/
mkdir -p $downloadDir

echo '0-1023的端口需要管理员权限才能绑定。1024及以上 不需要管理员权限。'
echo '输入nginx监听的端口（建议使用8080）：'
read port

#nginx、php运行用户
lnmpUser=$(whoami)

#lnmp安装目录。无需管理员权限，安装到$HOME即可。
prefix=$HOME

if [ $i = 'online' ]; then
    echo '正在在线检查官方最新稳定版'
else
    echo '正在离线检查版本'
fi

#如果在线安装，则每次在线检查新版本
#如果离线安装，则每次本地取版本号即可。如果本地文件不存在，也需要联网下载。

#检查pcre版本
#nginx 依赖 pcre源代码。如果没有，则报错：./configure: error: the HTTP rewrite module requires the PCRE library.  You can either disable the module by using --without-http_rewrite_module option, or install the PCRE library into the system, or build the PCRE library statically from the source with nginx by using --with-pcre=<path> option.
cd $downloadDir
if [ $i = 'online' ] || [ ! -f "$downloadDir"pcre.html ]; then
    echo '在线检查pcre'
    wget -nv http://pcre.org/ -O pcre.html
fi
#pcre 官方下载页面。格式为 ...The latest release of the PCRE library is 8.32. You can download...
html=$(cat pcre.html)

#截取字符串，从左向右截取第一个string后的字符串
tmp=${html#*'The latest release of the PCRE library is '}

#从右向左截取最后一个string后的字符串
pcreVersion=${tmp%%'. You can download'*}
echo 'pcre:' $pcreVersion


#检测nginx版本
cd $downloadDir
if [ $i = 'online' ] || [ ! -f "$downloadDir"nginx.html ]; then
    echo '在线检查nginx'
    wget -nv http://nginx.org/en/download.html -O nginx.html
fi
#nginx 官方下载页面。格式为 ...<h4>Stable version</h4></center><table width="100%"><tr><td width="20%"><a href="/en/CHANGES-1.2">CHANGES-1.2</a></td><td width="20%"><a href="/download/nginx-1.2.7.tar.gz">nginx-1.2.7</a>...
html=$(cat nginx.html)

#截取字符串，从左向右截取第一个string后的字符串，得到</h4></center><table width="100%"><tr><td width="20%"><a href="/en/CHANGES-1.2">CHANGES-1.2</a></td><td width="20%"><a href="/download/nginx-1.2.7.tar.gz">nginx-1.2.7</a>...
tmp=${html#*'Stable version'}

#从右向左截取最后一个string后的字符串，得到</h4></center><table width="100%"><tr><td width="20%"><a href="/en/CHANGES-1.2">CHANGES-1.2</a></td><td width="20%"><a href="/download/nginx-1.2.7
tmp2=${tmp%%'.tar.gz'*}

#从左向右截取最后一个string后的字符串，得到1.2.7
nginxVersion=${tmp2##*'nginx-'}
echo 'nginx:' $nginxVersion


#检查PHP版本
cd $downloadDir
if [ $i = 'online' ] || [ ! -f "$downloadDir"php.html ]; then
    echo '在线检查php'
    wget -nv http://php.net/downloads.php -O php.html
fi
#php 官方下载页面。格式为 ...<h1 id="v5.4.12">PHP 5.4.12 (Current stable)</h1> ...
html=$(cat php.html)
#从右向左截取最后一个string后的字符串，得到...<h1 id="v5.4.12">PHP 5.4.12 (
tmp=${html%%'Current stable'*}

#从右向左截取第一个string后的字符串，得到...<h1 id="v5.4.12">PHP 5.4.12
tmp2=${tmp%' '*}

#从左向右截取最后一个string后的字符串，得到5.4.12
phpVersion=${tmp2##*' '}
echo 'php:' $phpVersion


echo '准备pcre源代码'
pcreSrcDir=pcre-$pcreVersion
pcreFile=$pcreSrcDir.tar.bz2
cd $downloadDir
if [ ! -f "$pcreFile" ]; then
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/$pcreFile
fi
rm -rf $pcreSrcDir
tar -jxvf $pcreFile > /dev/null


echo '安装nginx'
nginxSrcDir=nginx-$nginxVersion
nginxFile=$nginxSrcDir.tar.gz
cd $downloadDir
if [ ! -f "$nginxFile" ]; then
    wget http://nginx.org/download/$nginxFile
fi
rm -rf $nginxSrcDir
tar -zxvf $nginxFile > /dev/null
rm -rf $prefix/nginx
cd "$downloadDir""$nginxSrcDir"
./configure --prefix=$prefix/nginx --with-pcre="$downloadDir""$pcreSrcDir"
make
make install
cd "$downloadDir"
rm -rf $nginxSrcDir
rm -rf $pcreSrcDir
sed -i "s|#user  nobody;|user  $lnmpUser;|g" $prefix/nginx/conf/nginx.conf
sed -i "s|#pid|pid|" $prefix/nginx/conf/nginx.conf
sed -i "s|#gzip|gzip|" $prefix/nginx/conf/nginx.conf
sed -i "s|listen       80;|listen $port default;|" $prefix/nginx/conf/nginx.conf
#除了dev环境，其他环境为了安全都要 禁止IP访问 和 未绑定域名指向
sed -i "s|server_name  localhost;|return 403;|" $prefix/nginx/conf/nginx.conf
sed -i "s|^    }|    }\n    include vhosts/*.conf;|" $prefix/nginx/conf/nginx.conf
mkdir -p $prefix/nginx/logs/localhost/
mkdir -p $downloadDir/nginx/conf/vhosts/
if [ $i = 'online' ] || [ ! -f "$downloadDir"nginx/conf/vhosts/localhost.conf ]; then
    wget -nv -O "$downloadDir"nginx/conf/vhosts/localhost.conf http://code.taobao.org/svn/lnmp/trunk/src/nginx/conf/vhosts/localhost.conf
    cd "$downloadDir"nginx/html/localhost/
    wget -nv -O index.html http://code.taobao.org/svn/lnmp/trunk/src/nginx/html/localhost/index.html
    wget -nv -O index.php http://code.taobao.org/svn/lnmp/trunk/src/nginx/html/localhost/index.php
    wget -nv -O favicon.ico http://code.taobao.org/svn/lnmp/trunk/src/nginx/html/localhost/favicon.ico
    wget -nv -O robots.txt http://code.taobao.org/svn/lnmp/trunk/src/nginx/html/localhost/robots.txt
fi

cp -R "$downloadDir"nginx $prefix
sed -i "s/listen       8080;/listen       $port;/"  $prefix/nginx/conf/vhosts/*.conf

cat > "$prefix"/nginx/nginx.sh <<EOF
#!/bin/bash
$prefix/nginx/sbin/nginx \$*
EOF
chmod +x "$prefix"/nginx/nginx.sh


echo 'nginx安装完成。启动nginx'
$prefix/nginx/nginx.sh
echo '测试访问http://localhost:'"$port"'/index.html'
curl -i 'http://localhost:'"$port"'/index.html'


echo '安装php'
phpSrcDir=php-$phpVersion
phpFile=$phpSrcDir.tar.bz2
cd $downloadDir
if [ ! -f "$phpFile" ]; then
    wget -O $phpFile http://php.net/get/$phpFile/from/this/mirror
fi
rm -rf $phpSrcDir
rm -rf $prefix/php
tar -jxvf $phpFile > /dev/null
rm -rf $prefix/php
cd $phpSrcDir
#--enable-fpm       进程管理器。nginx需要
#--enable-bcmath    高精度数学。float加减乘除比大小需要。
#--with-curl        curl。用于http请求。
#--with-mcrypt      加密。
#--enable-mbstring  多字节字符串。用于处理unicode字符。
#--with-pdo-mysql   PDO封装mysql。PHP官方推荐使用。
#--with-mysqli      封装mysql。用于mysql 5+。PHP官方推荐使用。
#--with-mysql       封装mysql。用于mysql 4。PHP官方不推荐使用。
#--with-openssl     stmp https发信时需要。
#--with-imap-ssl    imap https收信时需要。
#--with-gd          常用的图形库。
#--with-jpeg-dir    调用系统的libjpeg。
#--with-png-dir     调用系统的libpng。
#--enable-exif      开启exif。压缩图片时要根据方向orientation进行旋转。
#--enable-zip       开启zip。
#--with-xsl         phpdoc2 要用。

./configure --prefix=$prefix/php --enable-fpm --enable-bcmath --with-curl --with-mcrypt --enable-mbstring --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql --with-openssl --with-imap-ssl --with-gd --with-jpeg-dir=/usr/lib/ --with-png-dir=/usr/lib/ --enable-exif --enable-zip --with-xsl
make
make install
if [ $env = 'prod' ]; then
    cp php.ini-production $prefix/php/lib/php.ini
else
    cp php.ini-development $prefix/php/lib/php.ini
fi
cd "$downloadDir"
rm -rf $phpSrcDir
sed -i "s|;include_path = \".:/php/includes\"|include_path = \"$prefix/php/lib/php\"|g" $prefix/php/lib/php.ini
#关闭http header中的X-Powered-By: PHP/x.x.x
sed -i "s/expose_php = On/expose_php = Off/g" $prefix/php/lib/php.ini
sed -i "s/;date.timezone.*/date.timezone = Asia\/Shanghai/g" $prefix/php/lib/php.ini

cp $prefix/php/etc/php-fpm.conf.default $prefix/php/etc/php-fpm.conf
sed -i "s|user = nobody|user = $lnmpUser|g" $prefix/php/etc/php-fpm.conf
sed -i "s|group = nobody|group = $lnmpUser|g" $prefix/php/etc/php-fpm.conf
sed -i "s|listen = 127.0.0.1:9000|listen = $prefix/php/var/run/php-fpm.sock|g" $prefix/php/etc/php-fpm.conf
sed -i "s|^;pid|pid|" $prefix/php/etc/php-fpm.conf
sed -i "s|^;error_log|error_log|" $prefix/php/etc/php-fpm.conf
sed -i "s|/home/lnmp|$prefix|g" $prefix/nginx/conf/vhosts/*.conf

cat > "$prefix"/php/php-fpm.sh <<EOF
#!/bin/bash
help="Usage: \$0 [-s signal]

Options:
  -h            : this help
  -s signal     : send signal to a master process: start, stop, reload(restart)
"
s="start"

while getopts s:h opt
do
    case \$opt in
    "s" )
        eval \$opt=\$OPTARG
        ;;
    *)
        echo "\$help"
        exit
        ;;
    esac
done
echo 'php-fpm'
case \$s in
"start" )
    echo '正在启动'
    $prefix/php/sbin/php-fpm
    echo '已启动'
    ;;
"stop" )
    echo '正在关闭'
    kill -INT \`cat $prefix/php/var/run/php-fpm.pid\`
    echo '已关闭'
    ;;
"restart"|"reload" )
    echo '正在重启'
    kill -USR2 \`cat $prefix/php/var/run/php-fpm.pid\`
    echo '已重启'
    ;;
esac
EOF
chmod +x "$prefix"/php/php-fpm.sh
echo 'php安装完成。'
echo '启动nginx：'"$prefix"'/nginx/nginx.sh'
echo '关闭nginx：'"$prefix"'/nginx/nginx.sh -s stop'
echo '重启nginx：'"$prefix"'/nginx/nginx.sh -s reload'
echo '启动php：'"$prefix"'/php/php-fpm.sh'
echo '关闭php：'"$prefix"'/php/php-fpm.sh -s stop'
echo '重启php：'"$prefix"'/php/php-fpm.sh -s reload'
"$prefix"/php/php-fpm.sh
"$prefix"/nginx/nginx -s reload
echo '测试访问http://localhost:'"$port"'/index.php'
curl -i 'http://localhost:'"$port"'/index.php'

mkdir -p "$downloadDir"pear
mkdir -p $HOME/tmp/pear/cache
mkdir -p $HOME/tmp/pear/temp
#修改pecl下载目录，使用pecl config-set无效，只能使用pear config-set
$prefix/php/bin/pear config-set download_dir "$downloadDir"pear
$prefix/php/bin/pear config-set cache_dir $HOME/tmp/pear/cache
$prefix/php/bin/pear config-set temp_dir $HOME/tmp/pear/temp


echo '是（y）否（n）安装php pecl（http、imagick、memcached）：'
read isInstallPhpPecl
if [ $isInstallPhpPecl = 'y' ]; then
    echo '正在检查pecl官方最新稳定版'
    #检查pecl http版本
    cd "$downloadDir"pear
    if [ $i = 'online' ] || [ ! -f pecl_http.info ]; then
        echo '在线检查pecl http'
        $prefix/php/bin/pecl remote-info pecl_http > pecl_http.info
    fi
    #官方下载页面。
    info=$(cat pecl_http.info)

    #截取字符串，从左向右截取第一个string后的字符串
    tmp=${info#*'Latest      '}

    #把\n替换成空格。因为${tmp%%'\n'*}无效，所以只能使用${tmp%%' '*}
    tmp=$(echo $tmp|sed "s/\n/ /g")

    #从右向左截取最后一个string后的字符串
    peclHttpVersion=${tmp%%' '*}
    echo 'pecl_http:' $peclHttpVersion


    #安装pecl http
    peclHttpFile=pecl_http-"$peclHttpVersion".tar
    cd "$downloadDir"pear
    if [ ! -f "$peclHttpFile" ]; then
        $prefix/php/bin/pecl download pecl_http
    fi
    $prefix/php/bin/pecl install ./$peclHttpFile
    sed -i "s|; Windows Extensions|extension=http.so\n; Windows Extensions|g" $prefix/php/lib/php.ini


    #imagick 3.0.1正式版不支持php 5.4，beta版支持。所以暂时使用beta版，当正式版支持php 5.4时，再修改。
    #检查imagick版本
    cd "$downloadDir"pear
    if [ $i = 'online' ] || [ ! -f imagick.info ]; then
        echo '在线检查pecl imagick'
        $prefix/php/bin/pecl remote-info imagick-beta > imagick.info
    fi
    #官方下载页面。
    info=$(cat imagick.info)

    #截取字符串，从左向右截取第一个string后的字符串
    tmp=${info#*'Latest      '}

    #把\n替换成空格。因为${tmp%%'\n'*}无效，所以只能使用${tmp%%' '*}
    tmp=$(echo $tmp|sed "s/\n/ /g")

    #从右向左截取最后一个string后的字符串
    imagickVersion=${tmp%%' '*}
    echo 'imagick:' $imagickVersion


    #安装pecl imagick
    imagickFile=imagick-"$imagickVersion".tar
    cd "$downloadDir"pear
    if [ ! -f "$imagickFile" ]; then
        $prefix/php/bin/pecl download imagick-beta
    fi
    $prefix/php/bin/pecl install ./$imagickFile
    sed -i "s|; Windows Extensions|extension=imagick.so\n; Windows Extensions|g" $prefix/php/lib/php.ini



    #检查memcached版本
    cd "$downloadDir"pear
    if [ $i = 'online' ] || [ ! -f memcached.info ]; then
        echo '在线检查pecl memcached'
        $prefix/php/bin/pecl remote-info memcached > memcached.info
    fi
    #官方下载页面。
    info=$(cat memcached.info)

    #截取字符串，从左向右截取第一个string后的字符串
    tmp=${info#*'Latest      '}

    #把\n替换成空格。因为${tmp%%'\n'*}无效，所以只能使用${tmp%%' '*}
    tmp=$(echo $tmp|sed "s/\n/ /g")

    #从右向左截取最后一个string后的字符串
    memcachedVersion=${tmp%%' '*}
    echo 'memcached:' $memcachedVersion


    #安装pecl memcached
    memcachedFile=memcached-"$memcachedVersion".tar
    cd "$downloadDir"pear
    if [ ! -f "$memcachedFile" ]; then
        $prefix/php/bin/pecl download memcached
    fi
    $prefix/php/bin/pecl install ./$memcachedFile
    sed -i "s|; Windows Extensions|extension=memcached.so\n; Windows Extensions|g" $prefix/php/lib/php.ini

    echo 'php pecl安装完成。'
    $prefix/php/php-fpm.sh -s reload
fi


echo '是（y）否（n）安装php pear（phpDocumentor、phpUnit）：'
read isInstallPhpPear
if [ $isInstallPhpPear = 'y' ]; then
    echo '正在检查pear官方最新稳定版'
    #开发环境 安装pear phpdoc
    if [ $env = 'dev' ]; then
        #检查phpDocumentor版本
        cd "$downloadDir"pear
        if [ $i = 'online' ] || [ ! -f phpDocumentor.info ]; then
            $prefix/php/bin/pear channel-discover pear.phpdoc.org
            echo '在线检查pear phpDocumentor'
            $prefix/php/bin/pear remote-info phpdoc/phpDocumentor-alpha > phpDocumentor.info
        fi
        #官方下载页面。
        info=$(cat phpDocumentor.info)

        #截取字符串，从左向右截取第一个string后的字符串
        tmp=${info#*'Latest      '}

        #把\n替换成空格。因为${tmp%%'\n'*}无效，所以只能使用${tmp%%' '*}
        tmp=$(echo $tmp|sed "s/\n/ /g")

        #从右向左截取最后一个string后的字符串
        phpDocumentorVersion=${tmp%%' '*}
        echo 'phpDocumentor:' $phpDocumentorVersion


        #安装pear phpDocumentor
        phpDocumentorFile=phpDocumentor-"$phpDocumentorVersion".tar
        cd "$downloadDir"pear
        if [ ! -f "$phpDocumentorFile" ]; then
            $prefix/php/bin/pear download phpdoc/phpDocumentor-alpha
        fi
        $prefix/php/bin/pear install ./$phpDocumentorFile


        #开发环境 安装pear phpunit
        #检查PHPUnit版本
        cd "$downloadDir"pear
        if [ $i = 'online' ] || [ ! -f phpUnit.info ]; then
            $prefix/php/bin/pear channel-discover pear.phpunit.de
            echo '在线检查pear phpunit'
            $prefix/php/bin/pear remote-info pear.phpunit.de/PHPUnit > phpUnit.info
        fi
        #官方下载页面。
        info=$(cat phpUnit.info)

        #截取字符串，从左向右截取第一个string后的字符串
        tmp=${info#*'Latest      '}

        #把\n替换成空格。因为${tmp%%'\n'*}无效，所以只能使用${tmp%%' '*}
        tmp=$(echo $tmp|sed "s/\n/ /g")

        #从右向左截取最后一个string后的字符串
        PHPUnitVersion=${tmp%%' '*}
        echo 'PHPUnit:' $phpUnitVersion


        #安装pear PHPUnit
        phpUnitFile=PHPUnit-"$phpUnitVersion".tar
        cd "$downloadDir"pear
        if [ ! -f "$phpUnitFile" ]; then
            $prefix/php/bin/pear download pear.phpunit.de/PHPUnit
        fi
        $prefix/php/bin/pear install ./$phpUnitFile
    fi

    echo 'php pear安装完成。'
fi

echo 'mysql server准备工作：
1、管理员准备：
sudo apt-get install -y libaio1
sudo apt-get remove -y mysql-client
sudo rm -rf /etc/mysql/
sudo rm -rf /etc/my.cnf

2、是（y）否（n）安装mysql server？
'
read isInstallMysql
if [ $isInstallMysql != 'y' ]; then
    exit 0
fi

cd $downloadDir
if [ $i = 'online' ] || [ ! -f "$downloadDir"mysql.html ]; then
    echo '在线检查mysql'
    wget -nv http://dev.mysql.com/downloads/mysql/ -O mysql.html
fi
#官方下载页面。格式为 ...Generally Available (GA) Releases...<h1>MySQL Community Server 5.6.11</h1>...
html=$(cat mysql.html)

#截取字符串，从左向右截取第一个string后的字符串
tmp=${html#*'Generally Available (GA) Releases'}

#截取字符串，从左向右截取第一个string后的字符串
tmp=${html#*'<h1>MySQL Community Server '}

#从右向左截取最后一个string后的字符串
mysqlVersion=${tmp%%'</h1>'*}

echo 'MySQL Community Server :' $mysqlVersion

#mysql官方提供deb、rpm安装包，但需要管理员权限。所以下载源代码，编译安装。
#官方文档：http://dev.mysql.com/doc/refman/5.6/en/binary-installation.html
echo '安装mysql：'
mysqlSrcDir=mysql-"$mysqlVersion"-linux-glibc2.5-x86_64
mysqlFile="$mysqlSrcDir".tar.gz

#截取字符串，从左向右截取第一个string后的字符串
tmp=${mysqlVersion#*'-'}
#从右向左截取最后一个string后的字符串
one=${tmp%%'.'*}
#截取字符串，从左向右截取第一个string后的字符串
tmp=${mysqlVersion#*'.'}
#从右向左截取最后一个string后的字符串
two=${tmp%%'.'*}

mysqlTwoNumVersion=$one'.'$two

cd $downloadDir
if [ ! -f "$mysqlFile" ]; then
    wget http://cdn.mysql.com/Downloads/MySQL-"$mysqlTwoNumVersion"/"$mysqlFile"
fi
rm -rf $mysqlSrcDir
tar -zxvf $mysqlFile > /dev/null
rm -rf $prefix/mysql
mv $mysqlSrcDir "$prefix"/mysql
mkdir -p "$prefix"/mysql/var/run
cd "$prefix"/mysql
cp support-files/my-default.cnf ./my.cnf
sed -i "s|^# \*\*\*.*||"  ./my.cnf
echo 'basedir = '"$prefix"/mysql | tee -a ./my.cnf
echo 'datadir = '"$prefix"/mysql/data | tee -a ./my.cnf
echo 'port = 3306' | tee -a ./my.cnf
echo 'socket = '"$prefix"/mysql/var/run/mysqld.sock | tee -a ./my.cnf
echo 'character_set_server = utf8' | tee -a ./my.cnf
echo 'slow_query_log = 1' | tee -a ./my.cnf
echo '[client]' | tee -a ./my.cnf
echo 'socket = '"$prefix"/mysql/var/run/mysqld.sock | tee -a ./my.cnf
./scripts/mysql_install_db --defaults-file="$prefix"/mysql/my.cnf --random-passwords
rm my-new.cnf
echo 'mysql安装完成'
echo '--------------'
echo '随机密码请看：cat '"$prefix"'/.mysql_secret'
echo '登录：'"$prefix"'/mysql/mysql.sh -h127.0.0.1 -uroot -p'
echo '第一次登录后，需要修改密码：SET PASSWORD = PASSWORD("new-password")'
echo '启动mysql：'"$prefix"'/mysql/mysqld.sh'
echo '关闭mysql：'"$prefix"'/mysql/mysqld.sh -s stop'
echo '--------------'
cat > "$prefix"/mysql/mysql.sh <<EOF
#!/bin/bash
$prefix/mysql/bin/mysql --defaults-file=$prefix/mysql/my.cnf --default-character-set=utf8 --auto-rehash \$*
EOF
chmod +x "$prefix"/mysql/mysql.sh

cat > "$prefix"/mysql/mysqld.sh <<EOF
#!/bin/bash
help="Usage: \$0 [-s signal]

Options:
  -h            : this help
  -s signal     : send signal to a master process: start, stop
"
s="start"

while getopts s:h opt
do
    case \$opt in
    "s" )
        eval \$opt=\$OPTARG
        ;;
    *)
        echo "\$help"
        exit
        ;;
    esac
done
case \$s in
"start" )
    echo '正在启动mysqld，回车即可。'
    $prefix/mysql/bin/mysqld_safe --defaults-file=$prefix/mysql/my.cnf --ledir=$prefix/mysql/bin &
    ;;
"stop" )
    echo '关闭mysqld，需要密码：'
    $prefix/mysql/bin/mysqladmin  -S $prefix/mysql/var/run/mysqld.sock -uroot -p shutdown
    echo '已关闭'
    ;;
esac
EOF
chmod +x "$prefix"/mysql/mysqld.sh
"$prefix"/mysql/mysqld.sh
