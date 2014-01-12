#!/bin/bash
#
. ../base.sh

exe_cmd "sudo yum install -y ruby ruby-devel rubygems"
exe_cmd "sudo gem install jekyll"
exe_cmd "sudo gem install json"
exe_cmd "sudo gem install rdiscount"
