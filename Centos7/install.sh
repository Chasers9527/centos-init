#!/bin/bash
set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/../common/common.sh

[ $(id -u) != "0" ] && { ansi -n --bold --bg-red "请用 root 账户执行本脚本"; exit 1; }

MYSQL_ROOT_PASSWORD=`random_string`

function init_system {
    yum -y wget
    export LC_ALL="en_US.UTF-8"
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    locale-gen en_US.UTF-8
    locale-gen zh_CN.UTF-8

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    yum -y update

    init_alias
}

function init_alias {
    alias sudowww > /dev/null 2>&1 || {
        echo "alias sudowww='sudo -H -u ${WWW_USER} sh -c'" >> ~/.bash_aliases
    }
}

function init_repositories {
    # 使用阿里更新源
    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/epel-7.repo 
    yum clean all  
    yum makecache

    # EPEL安装
    yum install -y epel-release
    yum install -y yum-utils
    
    # nodejs 10 RPM
    curl -sL https://rpm.nodesource.com/setup_10.x | bash -

    # mysql RPM
    rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm

    # php RPM
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm   
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    
    # nginx 
    wget https://raw.githubusercontent.com/Chasers9527/centos-init/master/%20Centos7/config/unit.repo
    yum-config-manager --enable nginx-mainline

    yum update
}

function install_basic_softwares {
    yum install -y gcc-c++ make
    yum install -y curl git build-essential unzip supervisor wget
}

function install_node_yarn {
    yum install -y nodejs yarn
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && yarn config set registry https://registry.npm.taobao.org'
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && npm config set registry https://registry.npm.taobao.org'
}

function install_php {
    yum -y remove php*
    yum -y install php72w php72w-cli php72w-common php72w-curl php72w-pear php72w-devel php72w-embedded php72w-fpm php72w-gd php72w-mbstring \
                    php72w-mysqlnd php72w-opcache php72w-pdo php72w-xml php72w-zip php72w-pgsql php72w-sqlite3
    pecl install swoole
    echo "extension=swoole.so" >> /etc/php.ini
    pecl install redis
    echo "extension=redis.so" >> /etc/php.ini
}

function install_others {
    yum remove -y apache2
    
    # 关闭 mysql 80 使用 mysql 5.7
    yum-config-manager --disable mysql80-community
    yum-config-manager --enable mysql57-community

    yum install -y nginx mysql-community-server redis-server sqlite-devel
    chown -R ${WWW_USER}.${WWW_USER_GROUP} /var/www/
    systemctl enable nginx.service mysqld
    systemctl start mysqld
}

function install_composer {
    wget https://dl.laravel-china.org/composer.phar -O /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    sudo -H -u ${WWW_USER} sh -c  'cd ~ && composer config -g repo.packagist composer https://packagist.laravel-china.org'
}

call_function init_system "正在初始化系统" ${LOG_PATH}
call_function init_repositories "正在初始化软件源" ${LOG_PATH}
call_function install_basic_softwares "正在安装基础软件" ${LOG_PATH}
call_function install_php "正在安装 PHP" ${LOG_PATH}
call_function install_others "正在安装 Mysql / Nginx / Redis / Sqlite3" ${LOG_PATH}
call_function install_node_yarn "正在安装 Nodejs / Yarn" ${LOG_PATH}
call_function install_composer "正在安装 Composer" ${LOG_PATH}

ansi --green --bold -n "安装完毕"
ansi --green --bold "Mysql root 密码查看方式：" `grep 'temporary password' /var/log/mysqld.log`
ansi --green --bold -n "请手动执行 source ~/.bash_aliases 使 alias 指令生效。"