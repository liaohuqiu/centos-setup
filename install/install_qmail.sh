#!/bin/bash
#
. ../base.sh

install_dir="/data0/install"
untar_path=$install_dir/untar

qmail_install_dir=$install_dir"/qmail"

net_qmail="netqmail-1.05"
daemon_tool="daemontools-0.76"
ucspi_tcp="ucspi-tcp-0.88"

function init_qmail_env()
{
    exe_cmd "service sendmail stop"
    exe_cmd "chkconfig --del sendmail"
    if [ -d "/var/qmail" ]; then
        return;
    fi
    exe_cmd "mkdir -p /var/qmail"

    exe_cmd "/usr/sbin/groupadd nofiles"
    exe_cmd "/usr/sbin/useradd -g nofiles -d /var/qmail/alias alias -s /sbin/nologin"
    exe_cmd "/usr/sbin/useradd -g nofiles -d /var/qmail qmaild -s /sbin/nologin"
    exe_cmd "/usr/sbin/useradd -g nofiles -d /var/qmail qmaill -s /sbin/nologin"
    exe_cmd "/usr/sbin/useradd -g nofiles -d /var/qmail qmailp -s /sbin/nologin"
    exe_cmd "/usr/sbin/groupadd qmail"
    exe_cmd "/usr/sbin/useradd -g qmail -d /var/qmail qmailq -s /sbin/nologin"
    exe_cmd "/usr/sbin/useradd -g qmail -d /var/qmail qmailr -s /sbin/nologin"
    exe_cmd "/usr/sbin/useradd -g qmail -d /var/qmail qmails -s /sbin/nologin"
}

function untar_qmail_files()
{
    exe_cmd "make_dir $qmail_install_dir"
    exe_cmd "cd $qmail_install_dir"

    if [ ! -f $netqmail".tar.gz" ]; then
        exe_cmd "wget http://www.qmail.org/netqmail-1.05.tar.gz"
    fi
    if [ ! -f $ucspi_tcp".tar.gz" ]; then
        exe_cmd "wget http://cr.yp.to/ucspi-tcp/ucspi-tcp-0.88.tar.gz"
    fi
    if [ ! -f $daemontools".tar.gz" ]; then
        exe_cmd "wget http://cr.yp.to/daemontools/daemontools-0.76.tar.gz"
    fi

    exe_cmd "mkdir -p /package"
    exe_cmd "chmod 755 /package"
    exe_cmd "cp -rf $daemon_tools.tar.gz /package"

    exe_cmd "cd /package"
    exe_cmd "rm -rf $daemon_tools"
    exe_cmd "tar -zxvf $daemon_tools.tar.gz > /dev/null"
    exe_cmd "rm -rf $daemon_tools.tar.gz"

    exe_cmd "cd $qmail_install_dir"
    exe_cmd "rm -rf $net_qmail"
    exe_cmd "tar -zxvf $net_qmail.tar.gz > /dev/null"
    exe_cmd "cd $net_qmail"
    exe_cmd "sh collate.sh"

    exe_cmd "cd $qmail_install_dir"
    exe_cmd "rm -rf $ucspi_tcp"
    exe_cmd "tar -zxvf $ucspi_tcp.tar.gz > /dev/null"
}

function intall_qmail()
{
    exe_cmd "cd $qmail_install_dir"
    exe_cmd "cd $net_qmail/$net_qmail"
    exe_cmd "make setup check"
    exe_cmd "./config-fast 163.com"

    exe_cmd "cd $qmail_install_dir"
    exe_cmd "cd $ucspi_tcp"
    exe_cmd "make"
    exe_cmd "make setup check"

    exe_cmd "cd /package/admin/$daemon_tools"
    exe_cmd "package/install"

    exe_cmd "echo 3600 > /var/qmail/control/queuelifetime"
    #echo ":192.168.134.48" > /var/qmail/control/smtproutes

    exe_cmd "rm -rf /var/qmail/rc"
    exe_cmd "cp -af /var/qmail/boot/home /var/qmail/rc"

    exe_cmd "/var/qmail/rc &"
}
init_qmail_env
untar_qmail_files
intall_qmail
