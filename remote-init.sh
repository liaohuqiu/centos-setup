if [ ! $# -eq 1 ]; then
    echo "usage: $0 ssh-root-access"
    exit 1
fi

# 1. ssh to download script then run:
#       init basic env
#       add user / add sudo
#       remove script

cmd='wget https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/add-user-as-root.sh | sh'

# 2. generate authkey then copy to remote
# 3. login as new user, download script then 
