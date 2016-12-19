if [ ! $# -eq 3 ]; then
    echo "usage: $0 user ssh_pub_key hostname"
    exit 1
fi

function exe_cmd()
{
    echo $1
    eval $1
}

user=$1
ssh_pub_key=$2
hostname=$3

function init_env() {
    exe_cmd "yum install git -y"

    exe_cmd "firewall-cmd --zone=public --add-port=22/tcp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=53/udp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=80/tcp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=443/tcp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=11122/tcp --permanent"
    exe_cmd "firewall-cmd --permanent --zone=trusted --change-interface=docker0"
    exe_cmd "systemctl restart firewalld.service"
    exe_cmd "hostnamectl set-hostname $hostname"
}

function init_user() 
{
    time=`date +%s`
    user=$1
    key=$2
    home="/home/$user"

    if [ -d $home ]; then
        return
    fi

    file=add-user-without-passwd.sh
    cmd="curl -s https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init/$file?$time | bash -s $user"
    exe_cmd "$cmd"

    exe_cmd "cd $home"
    exe_cmd "mkdir $home/.ssh"
    exe_cmd "chmod 700 $home/.ssh"
    echo $key >> $home/.ssh/authorized_keys
    exe_cmd "chmod 600 $home/.ssh/authorized_keys"

    # # add ForwardAgent
    # cmd="curl -s https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/config-templates/ssh/server-config?$time > $home/.ssh/config"
    # exe_cmd "$cmd"
    # exe_cmd "chmod 600 $home/.ssh/config"

    # exe_cmd "echo 'ForwardAgent yes' >> /etc/ssh/ssh_config"

    exe_cmd "chown -R $user:$user $home/.ssh"
}

init_env
init_user $user "$ssh_pub_key"
