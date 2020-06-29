#!/bin/bash

read -p "Install web service (y/n) : " WEBSVC
read -p "Install mikbotam (y/n) : " MIKBOTAM

read -p "mikbotam version (sqlite/mysql) : " VERSION
if [ ! -d /apps ];then
	mkdir /apps
fi

if [ "$WEBSVC" == "y" ];then
	read -p "Please input domain : " DOMAIN
	if [ "$VERSION" == "sqlite" ];then
		apt update
		apt -y install nginx php-fpm php-sqlite3 supervisor sqlite3
	fi
	if [ "$VERSION" == "mysql" ];then 
		apt update
		apt -y install nginx php-fpm php-mysql supervisor mariadb-server
	fi
	## config
	mv conf/nginx/* /etc/nginx
	mv /etc/nginx/app.conf /etc/nginx/conf.d
	SOCK=$(grep "^listen " /etc/php/* -r|awk '{print $3}')
	sed -i "s+SOCK+$SOCK+" /etc/nginx/php_params
	sed -i "s+DOMAIN+$DOMAIN+" /etc/nginx/conf.d/app.conf
fi

if [ "$MIKBOTAM" == "y" ];then
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
fi

