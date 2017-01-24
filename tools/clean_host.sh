#!/bin/bash

systemctl stop rsyslog.service

yum clean all

> /var/log/anaconda.ifcfg.log
> /var/log/anaconda.log
> /var/log/anaconda.program.log
> /var/log/anaconda.storage.log
> /var/log/anaconda.syslog
> /var/log/anaconda.yum.log
> /var/log/boot.log
> /var/log/btmp
> /var/log/cron
> /var/log/dmesg
> /var/log/dracut.log
> /var/log/lastlog
> /var/log/maillog
> /var/log/message
> /var/log/secure
> /var/log/spooler
> /var/log/tallylog
> /var/log/wtmp
> /var/log/yum.log

rm -f /var/log/dmesg.old

> /root/.bash_history
