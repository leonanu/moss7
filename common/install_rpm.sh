#!/bin/bash

## change YUM repo
if ! grep '^CH_YUM' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${CHANGE_YUM} -eq 1 2>/dev/null ]; then
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.ori
        install -m 0644 ${TOP_DIR}/conf/yum/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
        yum clean all
        ## log installed tag
        echo 'CH_YUM' >> ${INST_LOG}
    fi
fi

## install EPEL repo
if ! grep '^ADD_EPEL' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/yum/epel.repo /etc/yum.repos.d/epel.repo
    yum clean all
    ## log installed tag
    echo 'ADD_EPEL' >> ${INST_LOG}
fi

## update system
if ! grep '^YUM_UPDATE' ${INST_LOG} > /dev/null 2>&1 ;then
    yum update -y || fail_msg "YUM Update Failed!"
    ## log installed tag
    echo 'YUM_UPDATE' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## install RPMs
if ! grep '^YUM_INSTALL' ${INST_LOG} > /dev/null 2>&1 ;then
yum install -y $(cat <<EOF
autoconf
automake
bind-utils
binutils
bison
blktrace
byacc
bzip2
bzip2-devel
c-ares
c-ares-devel
cmake
crontabs
curl
cyrus-sasl-devel
dmidecode
dos2unix
dstat
elinks
expect
file
flex
fontconfig-devel
freetype-devel
gcc
gcc-c++
gd-devel
git
glibc-devel
gmp
gmp-devel
gnupg2
graphviz
iotop
iptables
iptables-services
iptables-utils
iptraf-ng
lftp
libaio-devel
libcurl
libcurl-devel
libjpeg-turbo-devel
libmcrypt-devel
libnl-devel
libpng-devel
libpng-devel.i686
libstdc++-devel
libtiff-devel
libtool
libtool-ltdl-devel
libxml2-devel
libXpm-devel
libXpm-devel.i686
libxslt-devel
logrotate
lrzsz
lsof
make
man-db
man-pages
man-pages-overrides
expect
mlocate
mtr
net-tools
nscd
ntp
ntpdate
ntsysv
openldap
openldap-devel
openjpeg-devel
openjpeg-devel.i686
openssh-clients
openssl-devel
patch
patchutils
pciutils
pcre-devel
perl-DBD-MySQL
perl-Time-HiRes
popt-devel
readline-devel
rsync
screen
setuptool
sqlite
sqlite-devel
strace
sudo
sysstat
tcpdump
telnet
time
traceroute
tree
unzip
vim-filesystem
vim-minimal
vim-common
vim-enhanced
wget
which
whois
xz-devel
yum-plugin-priorities
zip
zlib-devel
EOF
) || fail_msg "Install RPMs Failed!"
## log installed tag
echo 'YUM_INSTALL' >> ${INST_LOG}
fi

## install saltstack
if [ ${INST_SALT} -eq 1 2>/dev/null ]; then
    if ! grep '^YUM_SALT' ${INST_LOG} > /dev/null 2>&1 ;then
        succ_msg "Getting SaltStack repository ..."
        yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm || fail_msg "Getting SaltStack Repository Failed!"
        echo 'priority=1' >> /etc/yum.repos.d/salt-latest.repo
        yum clean expire-cache
        yum install --disablerepo=epel salt-minion -y || fail_msg "SaltStack Minion Install Failed!"
        [ -f "/etc/salt/minion" ] && rm -f /etc/salt/minion
        install -m 0644 ${TOP_DIR}/conf/saltstack/minion /etc/salt/minion
        sed -i "s#^master.*#master: ${SALT_MASTER}#" /etc/salt/minion
        [ ! -d '/var/log/salt' ] && mkdir -m 0755 -p /var/log/salt
        systemctl start salt-minion.service
        systemctl enable salt-minion.service
        ## log installed tag
        echo 'YUM_SALT' >> ${INST_LOG}
    fi
fi
