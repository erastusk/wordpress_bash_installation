#!/bin/bash

WORDPRESS_ZIP=http://wordpress.org/latest.zip
WORDPRESS_TAR=https://wordpress.org/latest.tar.gz
WWW_DIR=/var/www
WORDPRESS_LATEST=${WWW_DIR}/latest.zip
WORDPRESS_LATEST_TAR=${WWW_DIR}/latest.tar.gz
DEF_CONF=/etc/nginx/sites-enabled/default
EXAMPLE_COM=${WWW_DIR}/html/example.com
PASSWORD=123456
DB_NAME=example_com_db
DB_USER=wordpress
MYSQL_STATUS=/var/run/mysqld/mysqld.sock
UNZIP_STATUS=""
FILE_TYPE=""
TAR=0
ZIP=1
## Setting up Mysql Unattended Environment
`export DEBIAN_FRONTEND="noninteractive"`
`echo "mysql-server mysql-server/root_password password $PASSWORD" | sudo debconf-set-selections`
`echo "mysql-server mysql-server/root_password_again password $PASSWORD" | sudo debconf-set-selections`


##########################################################################
# SYSTEM UPDATE AND PACKAGE INSTALLATIONS
##########################################################################


#Checking if this is a Ubuntu system otherwise end script
echo -e "\n#############################"
echo -e "Checking system version....."

system_check=`uname -a | awk '{print $4}' | grep "Ubuntu"` 
system_ver=`uname -a | awk '{print $3 $4}' | grep "Ubuntu"` 

if [ "$?" -ne 0 ]
then
	echo "THIS SCRIPT NEEDS TO BE RAN ON UBUNTU...EXITING";
	exit 1;
else
	echo "Ready to continue on $system_ver"
fi
echo -e "#############################"


apt_get_status()
{
	while :
	do
		echo -ne "."
		sleep 1
		if [[ `sudo pgrep apt-get | wc -l` -eq 0  &&  `sudo lsof /var/lib/dpkg/lock-frontend | wc -l` -eq 0 ]]
		then			
			break
		fi
	done
}

system_update()
{
	echo "Updating System First"
	sudo apt-get update -y  &>/dev/null &
	apt_get_status 
	if [ "$?" -eq 0 ]
	then
		echo -e "\nSUCCESSFULLY UPDATED SYSTEM"
		echo -e "#############################"
	fi
}	

php_install()
{
	sudo apt-get install php[0-9]+.[0-9]+-cli php[0-9]+.[0-9]+-fpm php[0-9]+.[0-9]+-curl php[0-9]+.[0-9]+-gd php[0-9]+.[0-9]+-mysql php[0-9]+.[0-9]+-mbstring -y  &>/dev/null &
	apt_get_status 
	if [ `dpkg --get-selections | grep  $i | wc -l` -gt 0 ]
	then
		echo -e "\nPHP SUCCESSFULLY INSTALLED"
		echo -e "#############################"
	else
		echo -e "\nPHP INSTALL FAILED, please retry"		
		echo -e "#############################"
		exit
	fi
}

nginx_install()
{
	sudo apt-get install nginx -y &>/dev/null &
	apt_get_status 	
	if [ `dpkg --get-selections | grep  $i | wc -l` -gt 0 ]
	then
		echo -e "\nNGINX SUCCESSFULLY INSTALLED"
		echo -e "#############################"
	else
		echo -e "\nNGINX INSTALL FAILED, please retry"		
		echo -e "#############################"
		exit
	fi
}

mysql_install()
{
	sudo apt-get install mysql-server mysql-client -y &>/dev/null &
	apt_get_status 
	if [ `dpkg --get-selections | grep  $i | wc -l` -gt 0 ]
	then
		echo -e "\nMYSQL SUCCESSFULLY INSTALLED"
		echo -e "#############################"
	else
		echo -e "\nMYSQL INSTALL FAILED, please retry"		
		echo -e "#############################"
		exit
	fi
}
misc_install()
{
	if [ `dpkg --get-selections | grep unzip | wc -l` -eq 0 ]
	then
		sudo apt-get install unzip -y  &>/dev/null &
		if [ `dpkg --get-selections | grep unzip | wc -l` -gt 0 ]
		then 
			UNZIP_STATUS=0
		else
			UNZIP_STATUS=1
		fi
	else
		UNZIP_STATUS=0
	fi		
}	

# Ensure apache2 is not installed, possible port 80 conflict with nginx

apache_check()
{
	if [ `dpkg --get-selections | grep  apache2 | wc -l` -gt 0 ]
	then
		sudo service apache2 stop
	fi	
}
##########################################################################
# MAIN
##########################################################################

system_update
apache_check
misc_install

# Need to ensure there are no dpkg processes running

apt_get_status 

for i in nginx mysql php
do
	if [ "$i" = "php" ] && [ `dpkg --get-selections | grep  $i | wc -l` -ne 11 ]
	then
		echo "$i is NOT installed, beginning installation"
		apt_get_status 
		php_install
	elif [ "$i" = "nginx" ] && [ `dpkg --get-selections | grep  $i | wc -l` -lt 5 ]	
	then
		echo -e "\n$i is NOT installed, beginning installation"
		apt_get_status 
		nginx_install
	elif [ "$i" = "mysql" ] && [ `dpkg --get-selections | grep  $i | wc -l` -lt 5 ]	
	then
		echo "$i is NOT installed, beginning installation"
		apt_get_status 
		mysql_install
	else
		echo "$i is already installed"
		echo -e "#############################"
	fi	
done


# MYSQL CONFIGURATION

## Enter domain name
echo -e "\n#############################"
echo -e "Please enter a domain you wish to use.."
sleep 1
echo -e "YOU ENTERED -> example.com <-"
echo -e "#############################\n"
echo "example.com localhost" | sudo tee -a /etc/hosts

## Configure wordpress db, user and permissions

sudo mysql -u root -p$PASSWORD <<EOF
CREATE DATABASE $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost IDENTIFIED BY "$PASSWORD";
FLUSH PRIVILEGES;
EOF

# WORDPRESS INSTALL AND CONFIGURATION

## Downloading wordpress in zip or tar format
if [ -d $WWW_DIR ]
then
	sudo mkdir -p $EXAMPLE_COM
else
	sudo mkdir -p $EXAMPLE_COM
fi

if [ -d $EXAMPLE_COM  ]
then
	echo -e "\n#############################"
	echo -e "\nPreparing to download the latest Wordpress file..."
	if [ `dpkg --get-selections | grep unzip | awk '{print $2}'`  = "install" ]
	then
		#Unzip installation successeded	
		cd $WWW_DIR
		sudo wget -q $WORDPRESS_ZIP 
		sudo unzip -q $WORDPRESS_LATEST 
		sudo mv $WWW_DIR/wordpress/* $EXAMPLE_COM/
		cd $EXAMPLE_COM
		FILE_TYPE=$ZIP
	else
		#Unzip installation failed using tar
		cd $WWW_DIR
		sudo wget -q $WORDPRESS_TAR 
		sudo tar -xzvf $WORDPRESS_LATEST_TAR &>/dev/null
		sudo mv $WWW_DIR/wordpress/* $EXAMPLE_COM/
		cd $EXAMPLE_COM
		FILE_TYPE=$TAR
	fi
fi

## Wordpress configuration

sudo cp $EXAMPLE_COM/wp-config-sample.php $EXAMPLE_COM/wp-config.php

if [ -f $EXAMPLE_COM/wp-config.php ]
then
	sudo sed -i "s/database_name_here/$DB_NAME/g" $EXAMPLE_COM/wp-config.php
	sudo sed -i "s/username_here/$DB_USER/g" $EXAMPLE_COM/wp-config.php
	sudo sed -i "s/password_here/$PASSWORD/g" $EXAMPLE_COM/wp-config.php
	sudo chown -R www-data: $EXAMPLE_COM
fi

# NGINX CONFIGURATION
# Begin Nginx Configuration
if [ -f $DEF_CONF ]
then 
	sudo mv /etc/nginx/sites-enabled/default /tmp
	sudo cp ~/example.com /etc/nginx/sites-available/
	sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
else
	echo "$DEF_CONF doesn't exist, Nginx installation failed ..exiting"
	exit
fi

## Begin Cleanup

echo -e "\n#############################"
echo "Cleanup...removing zip/tar files"
sudo rm -rf $WORDPRESS_LATEST
if [ $UNZIP_STATUS = 1 ]; then sudo rm -rf $WORDPRESS_LATEST_TAR; fi

echo "Cleanup...removing .conf example.com file"
sudo rm -rf ~/example.com
echo -e "#############################\n"
echo "Restarting NGINX...."

sudo service nginx restart
if [ "$?" -eq 0 ]
then
	echo -e "Successfully restarted Nginx with no errors"
	echo -e "\n#############################"
	echo -e "Enter example.com or localhost in a browser to finish Wordpress Configuration"
	echo -e "#############################\n"
else
	echo "Nginx failed to restarted"
	exit
fi
