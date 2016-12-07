#!/bin/bash
#

if [ $# -lt 2 ]; then
    echo "usage: $0 port password [method]"
    exit 1
fi
server_port=$1
password=$2
method=$3

if [[ -z "${method// }" ]]; then
    method="aes-128-cfb"
fi

read -d '' config_content <<_EOF
{
    "server_port": $server_port,
    "password": "$password",
    "method": "$method"
}
_EOF

cd /tmp
yum install -y gcc automake autoconf libtool make build-essential autoconf libtool
yum install -y curl curl-devel unzip zlib-devel openssl-devel perl perl-devel cpio expat-devel gettext-devel

if [ ! -d shadowsocks-libev* ]; then
    wget https://github.com/shadowsocks/shadowsocks-libev/archive/master.zip
    unzip master.zip
    cd shadowsocks-libev*
    ./autogen.sh
    ./configure --prefix=/usr && make
    make install
    mkdir -p /etc/shadowsocks-libev
    cp ./rpm/SOURCES/etc/init.d/shadowsocks-libev /etc/init.d/shadowsocks-libev
fi
echo "$config_content" > /etc/shadowsocks-libev/config.json
chmod +x /etc/init.d/shadowsocks-libev
service shadowsocks-libev restart
