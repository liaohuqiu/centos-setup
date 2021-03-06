prj_path=$(cd $(dirname $0); pwd -P)
config_templates_path="$prj_path/config-templates"

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

function init_env() {
    exe_cmd "hostnamectl set-hostname $hostname"
    exe_cmd "firewall-cmd --zone=public --add-port=22/tcp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=53/udp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=80/tcp --permanent"
    exe_cmd "firewall-cmd --zone=public --add-port=443/tcp --permanent"

    exe_cmd "firewall-cmd --permanent --zone=trusted --change-interface=docker0"
    exe_cmd "firewall-cmd --permanent --direct --add-rule  ipv4 nat POSTROUTING 0 -j MASQUERADE"

    exe_cmd "systemctl start firewalld.service"
    exe_cmd "sudo systemctl enable firewalld && sudo systemctl start firewalld.service"

    exe_cmd 'sudo brctl addbr docker0'
    exe_cmd 'sudo ip addr add 172.20.0.0/16 dev docker0'
    exe_cmd 'sudo ip link set dev docker0 up'
    exe_cmd "yum install git docker -y"
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
		# build docker config
		local docker_config_path='/etc/sysconfig'
        if [ ! -d "$docker_config_path" ]; then
            exe_cmd "sudo mkdir $docker_config_path"
        fi
        exe_cmd "sudo cp $config_templates_path/docker/docker.conf $docker_config_path/docker"
        exe_cmd "sudo cp $config_templates_path/docker/docker.service /usr/lib/systemd/system/docker.service"
        exe_cmd "sudo cp $config_templates_path/docker/kubernetes.repo /usr/lib/systemd/system/docker.service"

        exe_cmd "sudo setenforce 0"
        exe_cmd "sudo systemctl enable docker && sudo systemctl start docker"

        exe_cmd "sudo yum install -y docker kubelet kubeadm kubectl kubernetes-cni"
        exe_cmd "sudo systemctl enable kubelet && sudo systemctl start kubelet"
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

function install_tools() {
    exe_cmd "sudo yum install -y htop syssstat dig lsof"
    exe_cmd "sudo chmod +s `which ping`"
}

function install_fail2ban() {
    exe_cmd "sudo yum install -y fail2ban"
    exe_cmd "sudo yum install -y epel-release"
    exe_cmd "sudo systemctl enable fail2ban"
    exe_cmd "sudo cp $config_templates_path/fail2ban/jail.local /etc/fail2ban/jail.local"
    exe_cmd "sudo systemctl restart fail2ban"
}

init
create_dir
install_pip
install_docker
install_fail2ban
install_tools
