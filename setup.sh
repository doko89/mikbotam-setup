#!/bin/bash
## script by doko89

clear
echo "==================================="
echo "script mikbotam installer by doko89"
echo "==================================="

read -p "Install web service (y/n) : " WEBSVC
read -p "Install mikbotam (y/n) : " MIKBOTAM

read -p "mikbotam version (sqlite/mysql) : " VERSION
if [ ! -d /apps ];then
	mkdir /apps
fi

if [ "$WEBSVC" == "y" ];then
	read -p "Please input domain : " DOMAIN
	clear
	echo "======================"
	echo "Installing packages..."
	echo "======================"
	if [ "$VERSION" == "sqlite" ];then
		apt update
		apt -yq install nginx php-fpm php-sqlite3 php-curl supervisor sqlite3 curl
	fi
	if [ "$VERSION" == "mysql" ];then 
		apt update
		apt -yq install nginx php-fpm php-mysql php-curl supervisor mariadb-server curl
	fi
	## config
	cp conf/nginx/* /etc/nginx
	mv /etc/nginx/app.conf /etc/nginx/conf.d
	SOCK=$(grep "^listen " /etc/php/* -r|awk '{print $3}')
	sed -i "s+SOCK+$SOCK+" /etc/nginx/php_params
	sed -i "s+DOMAIN+$DOMAIN+" /etc/nginx/conf.d/app.conf
	# delete default vhost
	PHPFPM=$(systemctl list-units --type=service|grep php|awk '{print $1}')
	rm /etc/nginx/sites-enabled/*
        echo "======================"
        echo "Restarting services..."
        echo "======================"
	for i in nginx $PHPFPM;do systemctl restart $i;done
fi

if [ "$MIKBOTAM" == "y" ];then
        echo "======================"
        echo "Installing Mikbotam..."
        echo "======================"

	if [ -d /apps/mikbotam ];then
		mv /apps/mikbotam /apps/mikbotam.bak
	fi
	if [ "$VERSION" == "sqlite" ];then
		tar xf sources/mikbotam.sqlite.tar.gz -C /apps
	fi
	if [ "$VERSION" == "mysql" ];then
		tar xf sources/mikbotam.mysql.tar.gz -C /apps
		#create database
		echo "create database bangacil"|mysql
		echo "CREATE USER bangacil@localhost IDENTIFIED BY 'admin12345';" |mysql
		echo "GRANT ALL PRIVILEGES ON * . * TO bangacil@localhost"|mysql
		cat /apps/mikbotam/config/Newdatabase.sql |mysql bangacil
	fi
	# config
	chown -R www-data.www-data /apps
	## add long-polling
	cp conf/supervisor/long-polling.conf /etc/supervisor/conf.d/
	supervisorctl reload
	crontab -l > /root/cron.backup
	crontab conf/cron
	echo "setup mikbotam Done!!!"
fi
        echo "=============="
        echo "Extra Tools..."
        echo "=============="

read -p "Do you want to install mikhmon (y/n) : " MIKHMON
if [ "$MIKHMON" == "y" ];then
	read -p "Mikhmon domain : " MIKHDOM
	git clone https://github.com/laksa19/mikhmonv3.git /apps/mikhmon
	chown -R www-data.www-data /apps/mikhmon
	cp conf/nginx/app.conf /etc/nginx/conf.d/mikhmon.conf
	sed -i "s+DOMAIN+$MIKHDOM+" /etc/nginx/conf.d/mikhmon.conf
	sed -i "s+/apps/mikbotam+/apps/mikhmon+" /etc/nginx/conf.d/mikhmon.conf
	systemctl restart nginx
	echo "Setup mikhmon Done!!!"
fi
echo
echo
echo "url mikbotam : http://$DOMAIN"
if [ ! -z $MIKHDOM ];then
echo "url mikhmon : http://$MIKHDOM"
fi

## cleanup
DIR=$(pwd)
cd $HOME
rm -rf $DIR
