#!/bin/bash

[ ! -d '/usr/local/nginx/conf/ssl' ] && mkdir -p /usr/local/nginx/conf/ssl

if [ -e "/usr/local/nginx/conf/ssl/moss.pem" ];then
    exit 0
else
    PRE_VHOST_DN=www.example.com
    umask 77
    openssl req -utf8 -newkey rsa:2048 -keyout /usr/local/nginx/conf/ssl/moss.key -nodes -x509 -days 1825 -out /usr/local/nginx/conf/ssl/moss.crt -set_serial 0 -subj "/C=CN/ST=Moss/L=Moss/O=Moss Inc/CN=$VHOST_DN"
    cat /usr/local/nginx/conf/ssl/moss.key >  /usr/local/nginx/conf/ssl/moss.pem
    echo ""                           >> /usr/local/nginx/conf/ssl/moss.pem
    cat /usr/local/nginx/conf/ssl/moss.crt >> /usr/local/nginx/conf/ssl/moss.pem
fi
