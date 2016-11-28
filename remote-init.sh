if [ ! $# -eq 4 ]; then
    echo "usage: $0 ip-or-host-name user-want-to-create hostname ssh_pub_key_path"
    exit 1
fi

function exe_cmd() {
    echo $1
    eval $1
}

ip_or_host_name=$1
user=$2
hostname=$3
ssh_key_file_pub=$4

function init() {
    if [ ! -f $ssh_key_file_pub ]; then
        echo 'ssh key file not found'
        exit
    fi
}

function init_as_root() {
    ssh_cmd="ssh root@$ip_or_host_name"
    pub_key=`cat "$ssh_key_file_pub"`
    time=`date +%s`
    cmd="curl -s https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init/init-as-root.sh?time=$time | bash -s $user \"$pub_key\" $hostname"
    exe_cmd "$ssh_cmd '$cmd'"
}

function init_as_user() {
    ssh_cmd="ssh -A $user@$ip_or_host_name"

    # download
    cmd="curl -s https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init/init-as-user.sh?time=$time > init-as-user.sh"
    exe_cmd "$ssh_cmd '$cmd'"

    # login
    exe_cmd "$ssh_cmd"
}

init
init_as_root
sleep 1
init_as_user
