#!/bin/bash
set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/../common/common.sh

[ $(id -u) != "0" ] && { ansi -n --bold --bg-red "请用 root 账户执行本脚本"; exit 1; }

MYSQL_ROOT_PASSWORD=`random_string`

function init_system {
    yum -y install wget curl
    
    # 英文和时区的修改
    localectl  set-locale LANG=en_US.UTF-8
    timedatectl  set-timezone Asia/Shanghai

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
    mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/epel-7.repo 
    yum clean all  
    yum makecache

    # EPEL安装 + Nginx 
    yum install -y epel-release yum-utils
    
    # nodejs 12 RPM
    curl -sL https://rpm.nodesource.com/setup_12.x | bash -
    curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo

    # mysql RPM
    if [ -z "$(rpm -qa | grep mysql57-community)" ] ; then
        rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    fi
    # php RPM
    if [ -z "$(rpm -qa | grep epel-release)" ] ; then
        rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm   
    fi

    if [ -z "$(rpm -qa | grep webtatic)" ] ; then
        rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    fi
    
    # nginx 
    wget https://raw.githubusercontent.com/Chasers9527/centos-init/master/Centos7/config/nginx.repo
    mv -f nginx.repo /etc/yum.repos.d/nginx.repo
    yum-config-manager --enable nginx-mainline


    yum -y update
}

function install_basic_softwares {
    yum install -y gcc-c++ make
    yum install -y git build-essential unzip supervisor wget
}

function install_node_yarn {
    if ![ -x "$(command -v node)"]; then
        yum install -y nodejs
    fi
    if ![ -x "$(command -v yarn)"]; then
        yum install -y yarn
    fi
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && yarn config set registry https://registry.npm.taobao.org'
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && npm config set registry https://registry.npm.taobao.org'
}

function install_php {
    yum -y remove php*
    yum -y install php72w php72w-cli php72w-common php72w-curl php72w-pear php72w-devel php72w-embedded php72w-fpm php72w-gd php72w-mbstring \
                    php72w-mysqlnd php72w-opcache php72w-pdo php72w-xml php72w-zip php72w-pgsql php72w-sqlite3
    # pecl install swoole
    # echo "extension=swoole.so" >> /etc/php.ini
    # pecl install redis
    # echo "extension=redis.so" >> /etc/php.ini
}

function install_others {

    if [ -x "$(command -v apache2)"]; then
        yum remove -y apache2
    fi
    
    # 关闭 mysql 80 使用 mysql 5.7
    if ![ -x "$(command -v mysqld)"]; then
        yum install -y mysql-community-server
    fi
    yum install -y nginx redis sqlite-devel
    chown -R ${WWW_USER}.${WWW_USER_GROUP} /var/www/
    systemctl enable nginx.service mysqld
    systemctl start mysqld
}

function install_composer {
    wget https://dl.laravel-china.org/composer.phar -O /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    sudo -H -u ${WWW_USER} sh -c  'cd ~ && composer config -g repo.packagist composer https://packagist.laravel-china.org'
}

function install_zsh {
    yum install -y zsh
    sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}
# call_function init_system "正在初始化系统" ${LOG_PATH}
# call_function init_repositories "正在初始化软件源" ${LOG_PATH}
# call_function install_basic_softwares "正在安装基础软件" ${LOG_PATH}
# call_function install_php "正在安装 PHP" ${LOG_PATH}
call_function install_others "正在安装 Mysql / Nginx / Redis / Sqlite3" ${LOG_PATH}
call_function install_node_yarn "正在安装 Nodejs / Yarn" ${LOG_PATH}
call_function install_composer "正在安装 Composer" ${LOG_PATH}
call_function install_zsh "正在安装 oh-my-zsh&Zsh-" ${LOG_PATH}

ansi --green --bold -n "安装完毕"
ansi --green --bold "Mysql root 密码查看方式：" `grep 'temporary password' /var/log/mysqld.log`
ansi --green --bold -n "请手动执行 source ~/.bash_aliases 使 alias 指令生效。"
