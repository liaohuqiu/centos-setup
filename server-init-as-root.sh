if [ ! $# -eq 2 ]; then
    echo "usage: $0 user ssh_pub_key"
    exit 1
fi

function exe_cmd()
{
    echo $1
    eval $1
}
exe_cmd "yum install vim -y"
exe_cmd "yum install git -y"

function init_user() 
{
    user=$1
    ssh_pub_key=$2
    home="/home/$user"
    echo "Init user for path: $path"
    cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/add-user-without-passwd.sh | bash -s $user"
    exe_cmd "$cmd"
    exe_cmd "su $user"
    exe_cmd "cd $home"
    exe_cmd "mkdir $home/.ssh"
    exe_cmd "chmod 700 $home/.ssh"
    exe_cmd "echo '$ssh_pub_key' >> $home/.ssh/authorized_keys"
    exe_cmd "chmod 600 $home/.ssh/authorized_keys"
    cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/config/ssh/config > $home/.ssh/config"
    exe_cmd "$cmd"
    exe_cmd "chmod 600 $home/.ssh/config"
}

user=$1
ssh_pub_key=$2

ret=false
getent passwd $user >/dev/null 2>&1 && ret=true
if ! $ret; then
    init_user $user '$ssh_pub_key'
fi

if ! $ret; then
    exe_cmd "echo 'ForwardAgent yes' >> /etc/ssh/ssh_config"
fi
