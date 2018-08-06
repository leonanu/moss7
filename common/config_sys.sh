#!/bin/bash

## set hostname
if ! grep '^SET_HOSTNAME' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ! -z "${OS_HOSTNAME}" ];then
        OLD_HOSTNAME=$(hostname)
        hostnamectl set-hostname "${OS_HOSTNAME}"
        if [ -n "$(grep "$OLD_HOSTNAME" /etc/hosts)" ]; then
            sed -i "s/${OLD_HOSTNAME}//g" /etc/hosts
        fi
        sed -i "s/127\.0\.0\.1.*/127.0.0.1    ${OS_HOSTNAME} localhost localhost.localdomain/" /etc/hosts
    fi
    ## log installed tag
    echo 'SET_HOSTNAME' >> ${INST_LOG}
fi

# optimize /etc/resolv.conf
#if ! grep '^SET_RESOLV' ${INST_LOG} > /dev/null 2>&1 ;then
#    if ! grep 'dns=none' /etc/NetworkManager/NetworkManager.conf > /dev/null 2>&1 ;then
#        sed -i '/\[main\]/a\\dns=none' /etc/NetworkManager/NetworkManager.conf
#    fi
#    systemctl restart NetworkManager.service
#    if ! grep 'timeout' /etc/resolv.conf > /dev/null 2>&1 ;then
#        sed -i '1i\options timeout:1 attempts:1 rotate' /etc/resolv.conf
#    fi
#    systemctl restart NetworkManager.service
#    ## log installed tag
#    echo 'SET_RESOLV' >> ${INST_LOG}
#fi

# disable NetworkManager and optimize /etc/resolv.conf
if ! grep '^SET_RESOLV' ${INST_LOG} > /dev/null 2>&1 ;then
    systemctl stop NetworkManager.service
    systemctl disable NetworkManager.service
    if ! grep 'timeout' /etc/resolv.conf > /dev/null 2>&1 ;then
        sed -i '1i\options timeout:1 attempts:1 rotate' /etc/resolv.conf
    fi
    systemctl restart NetworkManager.service
    ## log installed tag
    echo 'SET_RESOLV' >> ${INST_LOG}
fi

# do not bell on tab-completion
if ! grep '^NO_BELL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep '#set bell-style none' /etc/inputrc > /dev/null 2>&1 ;then
        sed -i '1i\set bell-style none' /etc/inputrc
    else
        sed -i 's/^#set bell-style none/set bell-style none/g' /etc/inputrc
    fi
    echo 'NO_BELL' >> ${INST_LOG}
fi

## selinux
if ! grep '^SET_SELINUX' ${INST_LOG} > /dev/null 2>&1 ;then
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config 
    setenforce 0
    ## log installed tag
    echo 'SET_SELINUX' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## bashrc settings
if ! grep '^SET_BASHRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss bashrc' /etc/bashrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/bash/bashrc >> /etc/bashrc
    fi
    ## log installed tag
    echo 'SET_BASHRC' >> ${INST_LOG}
fi

## vimrc settings
if ! grep '^SET_VIMRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss vimrc' /etc/vimrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/vi/vimrc >> /etc/vimrc
    fi
    ## log installed tag
    echo 'SET_VIMRC' >> ${INST_LOG}
fi

## disable cron mail
if ! grep '^CRON_MAIL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'MAILTO' /var/spool/cron/root > /dev/null 2>&1 ;then
        echo 'MAILTO=""' >> /var/spool/cron/root
    fi
    ## log installed tag
    echo 'CRON_MAIL' >> ${INST_LOG}
fi
    
## set root password
if [ ! -z "${OS_ROOT_PASSWD}" ];then
    if ! grep '^SET_ROOT_PASSWORD' ${INST_LOG} > /dev/null 2>&1 ;then
        echo ${OS_ROOT_PASSWD} | passwd --stdin root
        ## log installed tag
        echo 'SET_ROOT_PASSWORD' >> ${INST_LOG}
    fi
fi

## %wheel users
if ! grep '^ADD_USER_WHEEL' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ -n "${GROUP_WHEEL}" ];then
        for ADD_USER_WHEEL in ${GROUP_WHEEL};do
            id ${ADD_USER_WHEEL} >/dev/null 2>&1 || useradd -u ${USER_WHEEL_FROM} -G wheel ${ADD_USER_WHEEL}
            if [ ! -f /home/${ADD_USER_WHEEL}/.passwd ];then
                TMP_PASS=$(mkpasswd -s 0 -l 10)
                echo ${TMP_PASS} | passwd --stdin ${ADD_USER_WHEEL}
                echo ${TMP_PASS} > /home/${ADD_USER_WHEEL}/.passwd
                chown root:root /home/${ADD_USER_WHEEL}/.passwd
                chmod 400 /home/${ADD_USER_WHEEL}/.passwd
            fi
            if [ ! -d /home/${ADD_USER_WHEEL}/.ssh ];then
                mkdir -m 0700 /home/${ADD_USER_WHEEL}/.ssh
                if [ ${ADD_USER_WHEEL} != moss ];then
                    if [ -f ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_WHEEL}.pub ];then
                        install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_WHEEL}.pub /home/${ADD_USER_WHEEL}/.ssh/authorized_keys
                    fi
                fi
                chown ${ADD_USER_WHEEL}:${ADD_USER_WHEEL} -R /home/${ADD_USER_WHEEL}/.ssh
            fi
            USER_WHEEL_FROM=$(expr ${USER_WHEEL_FROM} + 1)
        done
    fi
    ## log installed tag
    echo 'ADD_USER_WHEEL' >> ${INST_LOG}
fi

## %sa users
if ! grep '^ADD_USER_SA' ${INST_LOG} > /dev/null 2>&1 ;then
    groupadd sa -g 3000
    if [ -n "${GROUP_SA}" ];then
        for ADD_USER_SA in ${GROUP_SA};do
            id ${ADD_USER_SA} >/dev/null 2>&1 || useradd -u ${USER_SA_FROM} -G wheel ${ADD_USER_SA}
            if [ ! -f /home/${ADD_USER_SA}/.passwd ];then
                TMP_PASS=$(mkpasswd -s 0 -l 10)
                echo ${TMP_PASS} | passwd --stdin ${ADD_USER_SA}
                echo ${TMP_PASS} > /home/${ADD_USER_SA}/.passwd
                chown root:root /home/${ADD_USER_SA}/.passwd
                chmod 400 /home/${ADD_USER_SA}/.passwd
            fi
            if [ ! -d /home/${ADD_USER_SA}/.ssh ];then
                mkdir -m 0700 /home/${ADD_USER_SA}/.ssh
                if [ ${ADD_USER_SA} != moss ];then
                    if [ -f ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_SA}.pub ];then
                        install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_SA}.pub /home/${ADD_USER_SA}/.ssh/authorized_keys
                    fi
                fi
                chown ${ADD_USER_SA}:${ADD_USER_SA} -R /home/${ADD_USER_SA}/.ssh
            fi
            USER_SA_FROM=$(expr ${USER_SA_FROM} + 1)
        done
    fi
    ## log installed tag
    echo 'ADD_USER_SA' >> ${INST_LOG}
fi

## genarate Moss key pair
#if ! grep '^MOSS_KEY_PAIR' ${INST_LOG} > /dev/null 2>&1 ;then
#    ssh-keygen -t rsa -N '' -C $OS_HOSTNAME -f /home/moss/.ssh/id_rsa
#    chown -R moss.moss /home/moss/.ssh
#    chmod 400 /home/moss/.ssh/id_rsa*
#    ## log installed tag
#    echo 'MOSS_KEY_PAIR' >> ${INST_LOG}
#fi

## sudo
if ! grep '^SUDO' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0440 --backup=numbered ${TOP_DIR}/conf/sudo/sudoers /etc/sudoers
    ## log installed tag
    echo 'SUDO' >> ${INST_LOG}
fi
    
## openssh
if ! grep '^OPENSSH' ${INST_LOG} > /dev/null 2>&1 ;then
    sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config
    sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    sed -r -i 's/GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/ssh_config

    PUBKEY_NUM=$(ls -1 ${TOP_DIR}/etc/rsa_public_keys/*.pub 2>/dev/null | wc -l)
    PUBKEY_NUM_USER=$(ls -1 ${TOP_DIR}/etc/rsa_public_keys/*.pub 2>/dev/null | grep -v 'root.pub' | wc -l)

    if [ ${SSH_PASS_AUTH} -eq 0 2>/dev/null ]; then
        if [ ${PUBKEY_NUM} -eq 0 2>/dev/null ];then
            warn_msg "ERROR!"
            warn_msg "You want disable SSH password authentication."
            warn_msg "But no user SSH public key found!"
            warn_msg "You can not login system without user SSH key!"
            warn_msg "Please put user SSH RSA public keys in ${TOP_DIR}/etc/rsa_public_keys!"
            fail_msg "Moss installation terminated!"
        fi
        sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
    fi

    if [ ${SSH_ROOT_LOGIN} -eq 0 2>/dev/null ] && [ ${SSH_PASS_AUTH} -eq 0 2>/dev/null ]; then
        if [ ${PUBKEY_NUM_USER} -eq 0 2>/dev/null ];then
            warn_msg "ERROR!"
            warn_msg "You want disable root login via SSH."
            warn_msg "But no other user SSH public key found and password authentication was disabled!"
            warn_msg "You need to allow SSH password authentication or put other common user SSH public"
            warn_msg "key in ${TOP_DIR}/etc/rsa_public_keys!"
            fail_msg "Moss installation terminated!"
        fi
        sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    fi

    /etc/rc.d/init.d/sshd restart
    ## log installed tag
    echo 'OPENSSH' >> ${INST_LOG}
fi

## profiles
if ! grep '^PROFILE' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/profile/history.sh /etc/profile.d/history.sh
    install -m 0644 ${TOP_DIR}/conf/profile/path.sh /etc/profile.d/path.sh
    install -m 0644 ${TOP_DIR}/conf/profile/locale.sh /etc/profile.d/locale.sh
    ## log installed tag
    echo 'PROFILE' >> ${INST_LOG}
fi

## sysctl
if ! grep '^SYSCTL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss sysctl' /etc/sysctl.conf > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/sysctl/sysctl.conf >> /etc/sysctl.conf
        sysctl -p
    fi
    ## log installed tag
    echo 'SYSCTL' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## ipv6
if ! grep '^NO_IPV6' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${IPV6_OFF} -eq 1 2>/dev/null ]; then
        cat ${TOP_DIR}/conf/sysctl/no_ipv6.conf >> /etc/sysctl.conf
    fi
    ## log installed tag
    echo 'NO_IPV6' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## System Handler
if ! grep '^SYS_HANDLER' ${INST_LOG} > /dev/null 2>&1 ;then
    cat ${TOP_DIR}/conf/os/limits.conf >> /etc/security/limits.conf
    ## log installed tag
    echo 'SYS_HANDLER' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## nscd
if ! grep '^NSCD' ${INST_LOG} > /dev/null 2>&1 ;then
    cp -f /etc/nscd.conf /etc/nscd.conf.ori
    install -m 0644 ${TOP_DIR}/conf/nscd/nscd.conf /etc/nscd.conf
    systemctl restart nscd
    ## log installed tag
    echo 'NSCD' >> ${INST_LOG}
fi

## system service
if ! grep '^SYS_SERVICE' ${INST_LOG} > /dev/null 2>&1 ;then
    for SVC_ON in atd.service auditd.service chronyd.service crond.service dbus.service irqbalance.service network.service nscd.service sshd.service rsyslog.service;do
        systemctl enable ${SVC_ON} 2>/dev/null
        systemctl start ${SVC_ON} 2>/dev/null
    done

    for SVC_OFF in NetworkManager.service firewalld.service iptables.service ip6tables.service;do
        systemctl disable ${SVC_OFF} 2>/dev/null
        systemctl stop  ${SVC_OFF} stop 2>/dev/null
    done
    ## log installed tag
    echo 'SYS_SERVICE' >> ${INST_LOG}
fi

## enable rc-local service
if ! grep '^RC-LOCAL' ${INST_LOG} > /dev/null 2>&1 ;then
    chmod 755 /etc/rc.d/rc.local
    systemctl enable rc-local.service
    systemctl start rc-local.service
    ## log installed tag
    echo 'RC-LOCAL' >> ${INST_LOG}
fi
