#!/bin/bash
#
# StackScript Bash Library
#
# Copyright (c) 2010 Justin Ellison <justin@techadvise.com>, ported from Chris Aker's
# Ubuntu StackScript http://www.linode.com/stackscripts/view/?StackScriptID=1
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# * Neither the name of Linode LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific prior
# written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

###########################################################
# System
###########################################################

function system_update {
	yum -yq upgrade
}

function system_primary_ip {
	# returns the primary IP assigned to eth0
	echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
}

function get_rdns {
	# calls host on an IP address and returns its reverse dns

	if [ ! -e /usr/bin/host ]; then
		yum -yq install bind-utils > /dev/null
	fi
	echo $(host $1 | awk '/pointer/ {print $5}' | sed 's/\.$//')
}

function get_rdns_primary_ip {
	# returns the reverse dns of the primary IP assigned to this system
	echo $(get_rdns $(system_primary_ip))
}

function get_physical_memory {
	echo $(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
}

###########################################################
# Postfix
###########################################################

function postfix_install_loopback_only {
	# Installs postfix and configure to listen only on the local interface. Also
	# allows for local mail delivery

	yum -yq install postfix
	yum -yq remove sendmail

	touch /tmp/restart-postfix
}


###########################################################
# Apache
###########################################################

function apache_install {
	# installs the system default apache2 MPM
	yum -yq install httpd

	sed -i -e 's/^#NameVirtualHost \*:80$/NameVirtualHost *:80/' /etc/httpd/conf/httpd.conf

	touch /tmp/restart-httpd
}

function apache_tune {
	# Tunes Apache's memory to use the percentage of RAM you specify, defaulting to 40%

	# $1 - the percent of system memory to allocate towards Apache

	if [ ! -n "$1" ];
		then PERCENT=40
		else PERCENT="$1"
	fi

	yum -yq install httpd
	PERPROCMEM=10 # the amount of memory in MB each apache process is likely to utilize
	MEM=$(get_physical_memory)
	MAXCLIENTS=$((MEM*PERCENT/100/PERPROCMEM)) # calculate MaxClients
	MAXCLIENTS=${MAXCLIENTS/.*} # cast to an integer
	sed -i -e "s/\(^[ \t]*\(MaxClients\|ServerLimit\)[ \t]*\)[0-9]*/\1$MAXCLIENTS/" /etc/httpd/conf/httpd.conf

	touch /tmp/restart-httpd
}

function apache_virtualhost {
	# Configures a VirtualHost

	# $1 - required - the hostname of the virtualhost to create 

	if [ ! -n "$1" ]; then
		echo "apache_virtualhost() requires the hostname as the first argument"
		return 1;
	fi

	if [ -e "/etc/httpd/conf.d/${1}-vhost.conf" ]; then
		echo /etc/httpd/conf.d/${1}-vhost.conf already exists
		return;
	fi

	mkdir -p /srv/www/$1/public_html /srv/www/$1/logs

	echo "<VirtualHost *:80>" > /etc/httpd/conf.d/${1}-vhost
	echo "    ServerName $1" >> /etc/httpd/conf.d/${1}-vhost
	echo "    DocumentRoot /srv/www/$1/public_html/" >> /etc/httpd/conf.d/${1}-vhost
	echo "    <Directory /srv/www/$1/public_html/>" >> /etc/httpd/conf.d/${1}-vhost
	echo "    	AllowOverride All" >> /etc/httpd/conf.d/${1}-vhost
	echo "    </Directory>" >> /etc/httpd/conf.d/${1}-vhost
	echo "    ErrorLog /srv/www/$1/logs/error.log" >> /etc/httpd/conf.d/${1}-vhost
	echo "    CustomLog /srv/www/$1/logs/access.log combined" >> /etc/httpd/conf.d/${1}-vhost
	echo "</VirtualHost>" >> /etc/httpd/conf.d/${1}-vhost

	ln -s /etc/httpd/conf.d/${1}-vhost /etc/httpd/conf.d/${1}-vhost.conf

	touch /tmp/restart-httpd
}

function apache_virtualhost_from_rdns {
	# Configures a VirtualHost using the rdns of the first IP as the ServerName

	apache_virtualhost $(get_rdns_primary_ip)
}


function apache_virtualhost_get_docroot {
	if [ ! -n "$1" ]; then
		echo "apache_virtualhost_get_docroot() requires the hostname as the first argument"
		return 1;
	fi

	if [ -e /etc/httpd/conf.d/${1}-vhost ];
		then echo $(awk '/DocumentRoot/ {print $2}' /etc/httpd/conf.d/${1}-vhost )
	fi
}

function apache_mod_deflate_config {
	cat <<EOD > /etc/httpd/conf.d/deflate.conf
<IfModule mod_deflate.c>
        # these are known to be safe with MSIE 6
        AddOutputFilterByType DEFLATE text/html text/plain text/xml

        # everything else may cause problems with MSIE 6
        AddOutputFilterByType DEFLATE text/css
        AddOutputFilterByType DEFLATE application/x-javascript application/javascript application/ecmascript
        AddOutputFilterByType DEFLATE application/rss+xml

	# Exclude Not compatible browsers.
	BrowserMatch ^Mozilla/4 gzip-only-text/html
	BrowserMatch ^Mozilla/4\.0[678] no-gzip
	BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

</IfModule>
EOD
	touch /tmp/restart-httpd
}

###########################################################
# mysql-server
###########################################################

function mysql_install {
	# $1 - the mysql root password

	if [ ! -n "$1" ]; then
		echo "mysql_install() requires the root pass as its first argument"
		return 1;
	fi

	yum -yq install mysql-server

	/etc/init.d/mysqld start
	echo "Sleeping while MySQL starts up for the first time..."
	sleep 20
	#Remove anonymous users
	echo "DELETE FROM mysql.user WHERE User='';" | mysql -u root 
	#Remove remote root
	echo "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';" | mysql -u root 
	#Remove test db
	echo "DROP DATABASE test;" | mysql -u root 
	#Set root password
	echo "UPDATE mysql.user SET Password=PASSWORD('$1') WHERE User='root';" | mysql -u root 
	#Flush privs
	echo "FLUSH PRIVILEGES;" | mysql -u root 

}

function mysql_disable_innodb {
	echo "sskip-innodb" >> /etc/my.cnf # disable innodb - saves about 100M
	touch /tmp/restart-mysqld
}

function mysql_tune {
	# Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%

	# $1 - the percent of system memory to allocate towards MySQL

	if [ ! -n "$1" ];
		then PERCENT=40
		else PERCENT="$1"
	fi

	MEM=$(get_physical_memory)
	MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
	MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with

	# mysql config options we want to set to the percentages in the second list, respectively
	OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
	DISTLIST=(75 1 1 1 5 15)

	for opt in ${OPTLIST[@]}; do
		sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/my.cnf
	done

	for i in ${!OPTLIST[*]}; do
		val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
		if [ $val -lt 4 ]
			then val=4
		fi
		config="${config}\n${OPTLIST[$i]} = ${val}M"
	done

	sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/my.cnf

	touch /tmp/restart-mysqld
}

function mysql_create_database {
	# $1 - the mysql root password
	# $2 - the db name to create

	if [ ! -n "$1" ]; then
		echo "mysql_create_database() requires the root pass as its first argument"
		return 1;
	fi
	if [ ! -n "$2" ]; then
		echo "mysql_create_database() requires the name of the database as the second argument"
		return 1;
	fi

	echo "CREATE DATABASE $2;" | mysql -u root -p"$1"
}

function mysql_create_user {
	# $1 - the mysql root password
	# $2 - the user to create
	# $3 - their password

	if [ ! -n "$1" ]; then
		echo "mysql_create_user() requires the root pass as its first argument"
		return 1;
	fi
	if [ ! -n "$2" ]; then
		echo "mysql_create_user() requires username as the second argument"
		return 1;
	fi
	if [ ! -n "$3" ]; then
		echo "mysql_create_user() requires a password as the third argument"
		return 1;
	fi

	echo "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';" | mysql -u root -p"$1"
}

function mysql_grant_user {
	# $1 - the mysql root password
	# $2 - the user to bestow privileges 
	# $3 - the database

	if [ ! -n "$1" ]; then
		echo "mysql_create_user() requires the root pass as its first argument"
		return 1;
	fi
	if [ ! -n "$2" ]; then
		echo "mysql_create_user() requires username as the second argument"
		return 1;
	fi
	if [ ! -n "$3" ]; then
		echo "mysql_create_user() requires a database as the third argument"
		return 1;
	fi

	echo "GRANT ALL PRIVILEGES ON $3.* TO '$2'@'localhost';" | mysql -u root -p"$1"
	echo "FLUSH PRIVILEGES;" | mysql -u root -p"$1"

}

###########################################################
# PHP functions
###########################################################

function install_testing_repo {
	if [ -n "`grep CentOS /etc/redhat-release`" ] && [ ! -e /etc/yum.repos.d/CentOS-Testing.repo ]; then
		cat <<'EOD' > /etc/yum.repos.d/CentOS-Testing.repo
# CentOS-Testing:
# !!!! CAUTION !!!!
# This repository is a proving grounds for packages on their way to CentOSPlus and CentOS Extras.
# They may or may not replace core CentOS packages, and are not guaranteed to function properly.
# These packages build and install, but are waiting for feedback from testers as to
# functionality and stability. Packages in this repository will come and go during the
# development period, so it should not be left enabled or used on production systems without due
# consideration.
[testing]
name=CentOS-5 Testing
baseurl=http://dev.centos.org/centos/$releasever/testing/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://dev.centos.org/centos/RPM-GPG-KEY-CentOS-testing
includepkgs=php*
EOD
	fi
}

function php_install_apc {
	yum -yq install php-pear php-devel httpd-devel make
	echo yes | pecl install apc
	echo "extension=apc.so" > /etc/php.d/apc.ini
	if [ -n "$1" ]; then
		echo "apc.shm_size=${1}" >> /etc/php.d/apc.ini
	fi
	echo "apc.include_once_override = 1" >> /etc/php.d/apc.ini
	touch /tmp/restart-httpd
}

function php_install_with_apache {
	install_testing_repo
	yum -yq install php php-mysql php-cli mod_php php-cli php-gd
	touch /tmp/restart-httpd
}

function php_tune {
	# Tunes PHP to utilize up to nMB per process, 32 by default
	if [ ! -n "$1" ];
		then MEM="32"
		else MEM="${1}"
	fi

	sed -i'-orig' "s/memory_limit = [0-9]\+M/memory_limit = ${MEM}M/" /etc/php.ini
	touch /tmp/restart-httpd
}


function disable_service {
	if [ ! -n "$1" ]; then
		echo "disable_service() requires the service as its first argument"
		return 1;
	fi
	chkconfig --level=12345 $1 off
	/etc/init.d/${1} stop

}

function enable_epel_repo {
	rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-3.noarch.rpm
}

###########################################################
# Other niceties!
###########################################################

function goodstuff {
	yum -yq install vim-enhanced subversion
}


###########################################################
# utility functions
###########################################################

function restartServices {
	# restarts services that have a file in /tmp/needs-restart/

	for service in $(ls /tmp/restart-* | cut -d- -f2); do
		/etc/init.d/$service restart
		rm -f /tmp/restart-$service
	done
}

function randomString {
	if [ ! -n "$1" ];
		then LEN=20
		else LEN="$1"
	fi

	echo $(</dev/urandom tr -dc A-Za-z0-9 | head -c $LEN) # generate a random string
}
