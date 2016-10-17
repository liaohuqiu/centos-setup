function exe_cmd()
{
    echo $1
    eval $1
}

function ensure_dir()
{
    if [ ! -d $1 ]; then
        exe_cmd "mkdir -p $1"
    fi
}

exe_cmd "ensure_dir ~/git"

if [ ! -d ~/git/work-anywhere/ ]; then
    exe_cmd "cd ~/git"
    exe_cmd "git clone https://github.com/liaohuqiu/work-anywhere.git"
    exe_cmd "cd ~/git/work-anywhere/tools"
    exe_cmd "sh update-bash-profile.sh"
    exe_cmd "sh update-git-config.sh"
fi

if [ ! -d ~/git/vim_anywhere/ ]; then
    exe_cmd "cd ~/git"
    exe_cmd "git clone https://github.com/liaohuqiu/vim_anywhere.git"
    exe_cmd "cd ~/git/vim_anywhere/"
    exe_cmd "sh setup.sh"
fi

if [ ! -d ~/git/centos-setup/ ]; then
    exe_cmd "cd ~/git"
    exe_cmd "git clone https://github.com/liaohuqiu/centos-setup.git"
fi

function install_docker() {
    exe_cmd "sudo yum update"
    exe_cmd "curl -fsSL https://get.docker.com/ | sh"
    exe_cmd "sudo systemctl enable docker.service"
    exe_cmd "sudo systemctl start docker"
    user=`id -un`
    exe_cmd "sudo systemctl start docker"
    exe_cmd "sudo gpasswd -a $user docker"
    exe_cmd "sudo service docker restart"
    exe_cmd "newgrp docker"
    exe_cmd "sudo pip install docker-compose==1.8.1"
}

function install_pip() {
    exe_cmd "curl 'https://bootstrap.pypa.io/get-pip.py' -o 'get-pip.py'"
    exe_cmd "sudo python get-pip.py"
    exe_cmd "rm get-pip.py"
}

function create_dir() {
    local dir='/data0/docker'
    if [ ! -d $dir ]; then
        exe_cmd "sudo mkdir $dir"
    fi
    exe_cmd "sudo chown docker:docker $dir"
    exe_cmd "sudo chown g+w $dir"
    exe_cmd "sudo chown g+r $dir"
    exe_cmd "sudo chown g+x $dir"
}
install_pip
install_docker
create_dir
