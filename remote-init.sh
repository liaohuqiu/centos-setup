if [ ! $# -eq 3 ]; then
    echo "usage: $0 ip-or-host-name user-want-to-create hostname"
    exit 1
fi

function exe_cmd() {
    echo $1
    eval $1
}

hostname=$3
ip_or_host_name=$1
user=$2

keys_dir=~/.ssh/keys
ssh_keyfile=$keys_dir/auto-gen-$ip_or_host_name
ssh_keyfile_pub=$ssh_keyfile.pub

function init() {
    if [ ! -d $keys_dir ]; then
        exe_cmd "mkdir -p $keys_dir"
    fi
    chmod 700 $keys_dir
}

function gen_key() {

    if [ ! -f $ssh_keyfile_pub ]; then
        exe_cmd "ssh-keygen -t rsa -b 4096 -C $ip_or_host_name -f $ssh_keyfile"
        read -d '' config_content <<_EOF
Host $ip_or_host_name
    HostName $ip_or_host_name
    User $user
    IdentityFile $ssh_keyfile
_EOF

        echo "$config_content" >> ~/.ssh/config
        exe_cmd "chmod 700 ~/.ssh/config"
    fi
    exe_cmd "ssh-add $ssh_keyfile"
}

function init_as_root() {
    ssh_cmd="ssh root@$ip_or_host_name"
    pub_key=`cat "$ssh_keyfile_pub"`
    time=`date +%s`
    cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init/init-as-root.sh?time=$time | bash -s $user \"$pub_key\" $hostname"
    exe_cmd "$ssh_cmd $cmd"
}

function init_as_user() {
    ssh_cmd="ssh -A $user@$ip_or_host_name"
    cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init/init-as-user.sh?time=$time | bash init-workspace.sh"
    exe_cmd "$ssh_cmd '$cmd'"
    exe_cmd "$ssh_cmd"
}

init
gen_key
init_as_root
init_as_user
