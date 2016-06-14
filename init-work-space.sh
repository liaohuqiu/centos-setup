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
    exe_cmd "git clone git@github.com:liaohuqiu/work-anywhere.git"
    exe_cmd "cd ~/git/work-anywhere/"
    exe_cmd "sh tools/update-bash-profile.sh"
    exe_cmd "sh tools/update-git-config.sh"
fi

if [ ! -d ~/git/vim_anywhere/ ]; then
    exe_cmd "cd ~/git"
    exe_cmd "git clone git@github.com:liaohuqiu/vim_anywhere.git"
    exe_cmd "cd ~/git/vim_anywhere/"
    exe_cmd "sh setup.sh"
fi
