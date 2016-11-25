function exe_cmd() {
    echo $1
    eval $1
}

function ensure_dir()
{
    if [ ! -d $1 ]; then
        exe_cmd "mkdir -p $1"
    fi
}

function init() {
    # create docker group
    exe_cmd "getent group docker || sudo groupadd docker"

    # add docker:docker
    exe_cmd "id -u docker &>/dev/null || sudo useradd -r -g docker docker"

    # add current user to docker group
    user=`id -un`
    exe_cmd "sudo gpasswd -a $user docker"
}

function intall_basic_tools() {
    if [ ! -d ~/git/work-anywhere/ ]; then
        exe_cmd "cd ~/git"
        exe_cmd "git clone git@github.com:liaohuqiu/work-anywhere.git"
        exe_cmd "cd ~/git/work-anywhere/tools"
        exe_cmd "sh tools/update-bash-profile.sh"
        exe_cmd "sh tools/update-git-config.sh"
    fi

    exe_cmd "sudo yum install vim -y"
    exe_cmd "sudo yum install ctags -y"
    if [ ! -d ~/git/vim_anywhere/ ]; then
        exe_cmd "cd ~/git"
        exe_cmd "git clone git@github.com:liaohuqiu/vim_anywhere.git"
        exe_cmd "cd ~/git/vim_anywhere/"
        exe_cmd "sh setup.sh"
    fi

}

function install_pip() {
    if hash pip 2>/dev/null; then
        echo 'pip has installed'
    else
        exe_cmd "curl -s 'https://bootstrap.pypa.io/get-pip.py' -o 'get-pip.py'"
        exe_cmd "sudo python get-pip.py"
        exe_cmd "rm get-pip.py"
    fi
}

function install_docker() {

    # install docker
    if hash docker 2>/dev/null; then
        echo 'Docker has installed.'
    else
        exe_cmd "curl -fsSL https://get.docker.com/ | sh"
        exe_cmd "sudo systemctl enable docker.service"
        exe_cmd "sudo systemctl start docker"
        exe_cmd "sudo systemctl start docker"
        exe_cmd "sudo service docker restart"
    fi

    # install docker-compose
    if hash docker-compose 2>/dev/null; then
        echo "docker-compose==1.8.1 has installed."
    else
        exe_cmd "sudo pip install docker-compose==1.8.1"
    fi
}

function create_dir() {
    local dir='/data0/docker'
    if [ ! -d $dir ]; then
        exe_cmd "sudo mkdir -p $dir"
    fi
    exe_cmd "sudo chown docker:docker $dir"
    exe_cmd "sudo chmod g+w $dir"
    exe_cmd "sudo chmod g+r $dir"
    exe_cmd "sudo chmod g+x $dir"

    dir='/opt/data'
    if [ ! -d $dir ]; then
        exe_cmd "sudo mkdir -p $dir"
    fi
    exe_cmd "sudo chown docker:docker $dir"
    exe_cmd "sudo chmod g+w $dir"
    exe_cmd "sudo chmod g+r $dir"
    exe_cmd "sudo chmod g+x $dir"
}

init
create_dir
intall_basic_tools
install_pip
install_docker
