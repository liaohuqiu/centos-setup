if [ ! $# -eq 1 ]; then
    echo "usage: $0 username"
    exit 1
fi

function exe_cmd()
{
    echo $1
    eval $1
}

user=$1
exe_cmd "useradd $user"

# mode file tag_str content
function change_line() 
{
    local mode=$1
    local file=$2
    local tag_str=$3
    local content=$4
    local file_bak=$file".bak"
    local file_temp=$file".temp"
    cp -f $file $file_bak
    if [ $mode == "append" ]; then
        grep -q "$tag_str" $file || echo "$content" >> $file
    else
        cat $file |awk -v mode="$mode" -v tag_str="$tag_str" -v content="$content" '
        {
            if ( index($0, tag_str) > 0) {
                if ( mode == "after"){
                    printf( "%s\n%s\n", $0, content);

                } else if (mode == "before")
                {
                    printf( "%s\n%s\n", content, $0);

                } else if(mode == "replace") 
                {
                    print content;
                }
            } else if ( index ($0, content) > 0) 
            {
                # target content in line
                # do nothing
            } else
            {
                print $0;
            }
        }' > $file_temp
        mv $file_temp $file
    fi
}

change_line after '/etc/sudoers' '# Defaults   env_keep += "HOME"' 'Defaults   env_keep += "HOME"'
change_line replace '/etc/sudoers' 'Defaults    secure_path' 'Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin'
change_line replace '/etc/sudoers' 'Defaults    always_set_home' '#Defaults    always_set_home'
change_line append '/etc/sudoers' "$user ALL=(ALL) NOPASSWD:ALL"
