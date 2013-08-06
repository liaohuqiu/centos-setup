if [ ! $# -eq 2 ]; then
echo "usage: $0 username pwd"
exit 1
fi
user=$1
pwd=$2
useradd $user
echo "$pwd" |passwd $user --stdin
echo "$user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
