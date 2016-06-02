if [ ! $# -eq 1 ]; then
    echo "usage: $0 username"
    exit 1
fi

. ./base.sh

user=$1
useradd $user
passwd $user

change_line after '/etc/sudoers' '# Defaults   env_keep += "HOME"' 'Defaults   env_keep += "HOME"'
change_line replace '/etc/sudoers' 'Defaults    secure_path' 'Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin'
change_line replace '/etc/sudoers' 'Defaults    always_set_home' '#Defaults    always_set_home'
change_line append '/etc/sudoers' "$user ALL=(ALL) NOPASSWD:ALL"
