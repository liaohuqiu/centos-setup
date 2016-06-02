if [ ! $# -eq 2 ]; then
    echo "usage: $0 user ssh-root-access-cmd"
    exit 1
fi

function exe_cmd()
{
    echo $1
    eval $1
}

user=$1
ssh_cmd=$2
# 1. ssh to download script then run:
#       init basic env
#       add user / add sudo
#       remove script

cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/add-user-without-passwd.sh | bash -s $user"
exe_cmd "ssh_cmd '$cmd'"

# 2. generate authkey then copy to remote
# 3. login as new user, download script then 
