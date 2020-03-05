## 简介

适用于 Centos7 的 LNMP 安装脚本，并设置了国内镜像加速。

仿照 [summerblue/laravel-ubuntu-init](https://github.com/summerblue/laravel-ubuntu-init) 所写

请确保所有命令都以 root 账户执行，如果登录账户不是 root，则需要执行 `sudo -H -s` 切换为 root 账户后再下载安装。

## 软件列表

* Git
* PHP 7.2 [个人觉得还是 php7.2 最稳]
* Nginx 1.17
* MySQL 5.7
* Sqlite3
* Composer
* Nodejs 12
* Yarn
* Redis 5

## 可选软件列表

以下软件需手动执行安装脚本：

* Elasticsearch：`./Centos7/install_elasticsearch.sh`

## 安装步骤

```bash
wget -qO- https://raw.githubusercontent.com/Chasers9527/centos-init/master/download.sh - | bash
```

此脚本会将安装脚本下载到当前用户的 Home 目录下的 `laravel-ubuntu-init` 目录并自动执行安装脚本，在安装结束之后会在屏幕上输出 Mysql root 账号的密码，请妥善保存。

如果当前不是 root 账户则不会自动安装，需要切换到 root 账户后执行 `./Centos7/install.sh`。

## 日常使用

### 1. 新增 Nginx 站点

```bash
./Centos7/nginx_add_site.sh
```

会提示输入站点名称（只能是英文、数字、`-` 和 `_`）、域名（多个域名用空格隔开），确认无误后会创建对应的 Nginx 配置并重启 Nginx。

### 2. 新增 Mysql 用户、数据库

```bash
./Centos7/mysql_add_user.sh
```

会提示输入 root 密码，如果错误将无法继续。输入需要创建的 Mysql 用户名，以及确认是否需要创建对应用户名的数据库。

创建完毕之后会将新用户的密码输出到屏幕上，请妥善保存。

### 3. 以 www-data 身份执行命令

本项目提供了一个 `sudowww` 的 `alias`，当需要以 `www-data` 用户身份执行命令时（如 `git clone 项目`、`php artisan config:cache` 等），可以直接在命令前加上 `sudowww`，同时在原命令两端加上单引号，如：

```bash
sudowww 'php artisan config:cache'
```
