#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

U=$(who am i | awk '{print $1}')
rm -f /etc/apt/sources.list.d/cassandra.sources.list
debconf-set-selections <<< "mysql-server mysql-server/root_password password secret"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password secret"

echo -e "\n\r\e[32mRemoving apache\e[0m"
apt -qq remove apache2 --purge -y 

echo -e "\n\r\e[32mUpdating sources\e[0m"
add-apt-repository ppa:ondrej/php -y &> /dev/null 
apt-add-repository ppa:nginx/development -y &> /dev/null
apt-add-repository ppa:chris-lea/redis-server -y &> /dev/null
add-apt-repository ppa:webupd8team/java -y &> /dev/null
echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list
curl https://www.apache.org/dist/cassandra/KEYS | apt-key add -
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - &> /dev/null

echo -e "\n\r\e[32mUpdating and upgrading packages...\e[0m"
apt -qq autoremove -y 
apt -qq update -y 
apt -qq upgrade -y

echo -e "\n\r\e[32mInstalling first batch of packages...\e[0m"
apt -qq install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev ntp unzip software-properties-common curl make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin pv cifs-utils zsh

echo -e "\n\r\e[32mInstalling second batch of packages...\e[0m"
apt -qq install -y nodejs libcairo2-dev libjpeg8-dev libpango1.0-dev libgif-dev build-essential g++ libsodium-dev redis-server memcached beanstalkd mysql-server-5.7 cassandra

echo -e "\n\r\e[32mInstalling third and final batch of packages...\e[0m"
apt -qq install -y nginx php7.1 php7.1-cli php7.1-dev php7.1-pgsql php7.1-sqlite3 php7.1-gd php7.1-curl php7.1-memcached php7.1-imap php7.1-mysql php7.1-mbstring php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap php7.1-intl php7.1-readline php7.1-fpm

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
printf "\nPATH=\"$(sudo su - ${U} -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/${U}/.profile

echo -e "\n\r\e[32mConfiguring PHP 7.1\e[0m"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
sed -i "s/user www-data;/user ${U};/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
sed -i "s/user = www-data/user = ${U}/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = ${U}/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/listen\.owner.*/listen.owner = ${U}/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = ${U}/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.1/fpm/pool.d/www.conf

echo -e "\n\r\e[32mUpdating system services\e[0m"
service nginx restart
service php7.1-fpm restart
usermod -a -G www-data ${U}

sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
/etc/init.d/beanstalkd start

mysql -uroot -psecret -e "CREATE DATABASE reactivegaming;"

cat > /etc/supervisor/conf.d/echoserver.conf << EOF
[program:echoserver]
directory=/home/${U}/web/reactivegaming
command=/usr/bin/laravel-echo-server start
autostart=true
autorestart=true
user=${U}
redirect_stderr=true
stdout_logfile=/home/${U}/web/reactivegaming/storage/logs/%(program_name)s.log
EOF

cat > /etc/supervisor/conf.d/events.conf << EOF
[program:events]
process_name=%(program_name)s_%(process_num)02d
command=php /home/${U}/web/reactivegaming/artisan queue:work beanstalkd --sleep=3 --tries=5
autostart=true
autorestart=true
user=${U}
numprocs=1
redirect_stderr=true
stdout_logfile=/home/${U}/web/reactivegaming/storage/logs/%(program_name)s.log
EOF

echo -e "\e[32mNOTE: Two supervisord configs have been created at:\e[0m\n"
echo -e "  /etc/supervisor/conf.d/echoserver.conf"
echo -e "  /etc/supervisor/conf.d/events.conf\n\r"
echo -e "These files enable a WebSockets listen server and event queue"
echo -e "for the Reactive Gaming website. The website is expected to "
echo -e "reside at /home/${U}/web/reactivegaming. If this is not the"
echo -e "case, please edit the configs and configure the proper path.\n\r"

echo -e "\n\r\e[32mCleaning up...\e[0m"
systemctl enable supervisor.service
service supervisor start
supervisorctl reread && supervisorctl update && supervisorctl start all
apt -y update &> /dev/null
apt -y upgrade &> /dev/null
apt -y autoremove &> /dev/null
apt -y clean &> /dev/null

su ${U} << 'EOF'
 git config --global --bool pull.rebase true
EOF

git clone https://github.com/nathanburgess/dotfiles ~/dotfiles && cd ~/dotfiles && ./install.sh && cd && rm -fR ~/dotfiles

mkdir /home/${U}/.config
chown -R $U:$(id -gn $U) /home/${U}/.config
