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
git_path=~/git
path=$git_path/centos-setup

if [ ! -d $path ]; then
    exe_cmd "git clone git@github.com:liaohuqiu/centos-setup.git $git_path"
fi

exe_cmd "cd $path"
exe_cmd "sh local-int.sh
