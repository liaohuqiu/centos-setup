if [ ! $# -eq 2 ]; then
    echo "usage: $0 ip-or-host-name user"
    exit 1
fi

function exe_cmd()
{
    echo $1
    eval $1
}

ip_or_host_name=$1
user=$2
ssh_cmd="ssh root@$ip_or_host_name"

ssh_keyfile=~/.ssh/auto-gen-$ip_or_host_name
ssh_keyfile_pub=$ssh_keyfile.pub

if [ ! -f $ssh_keyfile_pub ]; then
    exe_cmd "ssh-keygen -t rsa -b 4096 -C $ip_or_host_name -f $ssh_keyfile"
read -d '' config_content <<_EOF
Host $ip_or_host_name
    HostName $ip_or_host_name
    User $user
    IdentityFile $ssh_keyfile
_EOF

    echo "$config_content" >> ~/.ssh/config
    chmod 700 ~/.ssh/config
fi

pub_key=`cat "$ssh_keyfile_pub"`

time=`date +%s`
cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init-as-root.sh?time=$time | bash -s $user \"$pub_key\""

$ssh_cmd $cmd

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

ssh_cmd="ssh -A $user@$ip_or_host_name"
cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/init-workspace.sh?time=$time | bash "
exe_cmd "$ssh_cmd '$cmd'"
