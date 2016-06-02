if [ ! $# -eq 3 ]; then
    echo "usage: $0 tag user ssh-root-access-cmd"
    exit 1
fi

function exe_cmd()
{
    echo $1
    eval $1
}

tag=$1
user=$2
ssh_cmd=$3

# 1. ssh to download script then run:
#       init basic env
#       add user / add sudo
#       remove script
# 2. generate authkey then copy to remote
# 3. login as new user, download script then 

pub_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNDjle7eM50ej3D+dyfD8nF6MGi2wQGrQhawNMlIs1OK4XgHgXPl5oLlVVr2BhJ+c4wxbGBQXcRlUplG94K58lf/1higsTsSj2QrJieQwI7DTKrVobZfrvITf4d5BXyKGUW5P7UDBSuuE0VcFtXZUjOTUSDaop+/DHrDSSvO36W1R8ElWFTFE6fYY5cW5jvQhVmuoxu/RFXfRiGzVZ7EADJLenEdVvqhI3cD2Nx7l2QOoVuMWamZeJnl94bOnObxqAB6V1lujPDvHic8C2L/+B1vB/Y9xDn9AKDagVSEV7kn42XZY4+RAD/Nf7v+S6NykrEsoiFbCEmNGfxvCoybvV for all'

time=`date +%s`
cmd="curl https://raw.githubusercontent.com/liaohuqiu/centos-setup/master/server-init-as-root.sh?time=$time | bash -s $user \"$pub_key\""
exe_cmd "ssh $ssh_cmd '$cmd'"
