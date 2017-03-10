#!/bin/bash

# This script use to genrate package MD5 value fit for Moss packages.info
# Usage: package_md5.sh /packages/path

if [ -z $1 ];then
    PKG_PATH='./'
else
    PKG_PATH=$1
fi

if [ ! -d ${PKG_PATH} ];then
    echo "${PKG_PATH} not a directory or not exist!"
    exit 1
fi

if ! ls ${PKG_PATH} | grep -E '*gz|*.tgz|*.bz2|*.rpm' > /dev/null 2>&1;then
    echo 'No tar bzip2 or RPM packages found!'
    exit 0
fi

if [ ! -x "/usr/bin/md5sum" ]; then
    echo 'md5sum not found! Installing...'
    yum install -y coreutils || echo 'md5sum install failed!' && exit 1
fi

PKG_LIST=$(ls ${PKG_PATH} | grep -E '*gz|*.tgz|*.bz2|*.rpm')

for PKG in ${PKG_LIST}
do
    MD5=$(md5sum ${PKG_PATH}/${PKG} | awk -F ' ' '{print $1}')
    echo "'${PKG}|${MD5}'"
done
