prj_path=$(cd $(dirname $0); pwd -P)
config_templates_path="$prj_path/config-templates"

function exe_cmd() {
    echo $1
    eval $1
}

function intall_basic_tools() {
    if [ ! -d ~/git/work-anywhere/ ]; then
        exe_cmd "cd ~/git"
        exe_cmd "git clone https://github.com/liaohuqiu/work-anywhere.git"
        exe_cmd "cd ~/git/work-anywhere/"
        exe_cmd "sh tools/update-bash-profile.sh"
        exe_cmd "sh tools/update-git-config.sh"
    fi

    exe_cmd "sudo yum install vim -y"
    exe_cmd "sudo yum install ctags -y"
    if [ ! -d ~/git/vim_anywhere/ ]; then
        exe_cmd "cd ~/git"
        exe_cmd "git clone https://github.com/liaohuqiu/vim_anywhere.git"
        exe_cmd "cd ~/git/vim_anywhere/"
        exe_cmd "sh setup.sh"
    fi
}

intall_basic_tools
