#!/bin/bash

. ./install_base.sh

app=nginx-1.4.2
url=http://nginx.org/download/nginx-1.4.2.tar.gz

nginx_path=/usr/local/nginx

download_src $app $url
goto_src $app

./configure --prefix=$nginx_path
make
make install
