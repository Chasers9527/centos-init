#!/bin/bash

{ # this ensures the entire script is downloaded #

lsb_release -d | grep 'CentOS' >& /dev/null
[[ $? -ne 0 ]] && { echo "仅支持 CentOS 系统"; exit 1; }

DISTRO=$(lsb_release -c -s)
[[ ${DISTRO} -ne "Core" ]] && { echo "仅支持 CentOS 系统"; exit 1; }

green="\e[1;32m"
nc="\e[0m"

HOME="/home"

echo -e "${green}===> 开始下载...${nc}"
cd ${HOME}
wget -q https://github.com/Chasers9527/centos-init/archive/master.zip -O centos-init.tar.gz
rm -rf centos-init
tar zxf centos-init.tar.gz
mv centos-init-master centos-init
rm -f centos-init.tar.gz
echo -e "${green}===> 下载完毕${nc}"
echo ""
echo -e "${green}安装脚本位于： ${HOME}/centos-init${nc}"

[ $(id -u) != "0" ] && {
    source ${HOME}/Centos7/common/ansi.sh
    ansi -n --bold --bg-yellow --black "当前账户并非 root，请用 root 账户执行安装脚本（使用命令：sudo -H -s 切换为 root）"
} || {
    bash ${HOME}/centos-init/Centos7/install.sh
}

cd - > /dev/null
} # this ensures the entire script is downloaded #
