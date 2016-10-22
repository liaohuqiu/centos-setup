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
path=~/git/centos-setup/

if [ ! -d $path ]; then
    exe_cmd "git clone git@github.com:liaohuqiu/centos-setup.git $path"
fi

exe_cmd "cd $path"
exe_cmd "sh local-int.sh
