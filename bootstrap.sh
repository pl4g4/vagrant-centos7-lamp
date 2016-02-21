#!/usr/bin/env bash
 
# ---------------------------------------
#          Virtual Machine Setup
# ---------------------------------------

#echo "Proxy Settings"

#change this settings if you are under a company proxy
#echo '
#HTTP_PROXY="http://proxy:8080"
#HTTPS_PROXY="http://proxy:8080"
#http_proxy="http://proxy:8080"
#https_proxy="http://proxy:8080"
#HTTPS_PROXY_REQUEST_FULLURI=false' >> /etc/environment 

#export http_proxy="http://proxy:8080"
#export https_proxy="http://proxy:8080"

#env | grep -i proxy

echo 'Setting everything up - This could take some time'

echo "Installing git"
sudo yum install -y git

echo "Installing vim"
sudo yum install -y vim

echo "Installing nano"
sudo yum install -y nano

echo "Installing wget"
sudo yum install -y wget

echo "Installing LAMP"

echo "Installing Apache"
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service

echo "Installing MYSQL"
sudo rpm -Uvh http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
sudo yum install -y mysql-community-server
sudo systemctl start mysqld
sudo systemctl enable mysqld

echo "Installing PHP"
sudo yum install -y php php-mysql mysql-client php-curl php-mcrypt php-gd curl php-fpm

echo "Installing XDEBUG"
sudo yum install -y make
sudo yum install -y php-devel
sudo yum install -y php-pear
sudo yum install -y gcc gcc-c++ autoconf automake
sudo pecl install Xdebug

echo "Installing Memcached"
sudo yum -y install memcached
sudo systemctl start memcached
sudo systemctl enable memcached
sudo systemctl status memcached

echo "linking Vagrant directory to Apache public directory"
sudo rm -rf /var/www/html
sudo ln -fs /vagrant /var/www/html

echo "Installing composer"
curl -s https://getcomposer.org/installer | php

echo "Make Composer available globally"
sudo mv composer.phar /usr/local/bin/composer

echo "Creating virtualhost"
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot /var/www/html
  ServerName dev.localhost
  ServerAlias *.dev.localhost
  ErrorLog /vagrant/logs/apache-error.log
  CustomLog /vagrant/logs/apache-access.log common
  php_value error_log /var/log/php-errors.log
  php_value xdebug.remote_log /var/log/xdebug.log
</VirtualHost>
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    SetEnv APP_ENV dev
    allow from all
</Directory>
EOF
)
echo "${VHOST}" > /etc/httpd/conf.d/qap.conf

echo 'Error Logs'
mkdir -p /vagrant/logs
cat /dev/null > /vagrant/logs/apache-error.log
cat /dev/null > /vagrant/logs/apache-access.log
cat /dev/null > /vagrant/logs/php_errors.log
cat /dev/null > /vagrant/logs/xdebug.log
chmod 755 /vagrant/logs

echo "Writing php.ini"
echo  ';xdebug
zend_extension="/usr/lib64/php/modules/xdebug.so"

xdebug.remote_connect_back=1
xdebug.remote_port="9000"
xdebug.remote_enable = 1

; set timezone
date.timezone = America/Winnipeg

; set error handling
error_reporting = E_ALL & ~E_NOTICE
display_errors = On
display_startup_errors = On
html_errors = On
xdebug.show_exceptions_trace = On

rs_server = dev' >> /etc/php.ini

echo  '127.0.0.1 dev.localhost' >> /etc/hosts


echo "Opening ports firewall centos7"
sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --zone=public --permanent --add-service=mysql
sudo firewall-cmd --zone=public --permanent --add-port=9000/tcp
sudo firewall-cmd --zone=public --permanent --add-port=22/tcp
sudo firewall-cmd --zone=public --permanent --add-port=2222/tcp
sudo firewall-cmd --zone=public --permanent --add-port=3306/tcp
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8080/tcp
sudo firewall-cmd --zone=public --permanent --add-port=11211/tcp
sudo firewall-cmd --reload

sudo systemctl restart httpd.service

echo "Installing pwgen"
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/p/pwgen-2.07-1.el7.x86_64.rpm
yum -y install pwgen

echo "Updating MYSQL root password"
MYSQLPASSWORD="`sudo grep 'temporary password' /var/log/mysqld.log | sed 's/.*root@localhost: //'`"
MYSQLNEWPASS=${MYSQL_PASS:-$(pwgen 16 -c -n -y 1)}

MYSQL=`which mysql`

$MYSQL -uroot -p$MYSQLPASSWORD --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQLNEWPASS';"

PASS=${MYSQL_PASS:-$(pwgen 16 -c -n -y 1)}
_word=$( [ ${MYSQL_PASS} ] && echo "preset" || echo "random" )

echo "=> Creating MySQL admin user with ${_word} password"

$MYSQL -uroot -p$MYSQLNEWPASS -e "CREATE USER 'admin'@'%' IDENTIFIED BY '$PASS'"
$MYSQL -uroot -p$MYSQLNEWPASS -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

echo 'LAMP Status'
echo "========================================================================="
sudo systemctl status httpd
sudo systemctl status mysqld
sudo systemctl status memcached
sudo firewall-cmd --zone=public --list-all
echo "========================================================================="

echo 'Software version'
echo "========================================================================="
httpd -v
php -v
mysql --version
echo "========================================================================="

echo "========================================================================"
echo "You can now connect to this MySQL Server using:"
echo "    mysql -uroot -p$MYSQLNEWPASS -h<host> -P<port>"
echo "    mysql -uadmin -p$PASS -h<host> -P<port>"
echo "========================================================================"

echo "=> Done!"