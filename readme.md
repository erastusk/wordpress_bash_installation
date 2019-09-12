Assumptions
------------
1. User has sudo access without password
2. Server the script is being ran on has internet access for apt-get commands
3. example.com is stored in the user's home directory ( ~/)
4. PHP,MYSQL,NGINX & WORDPRESS are NOT installed.

Libraries Used
--------------

PHP
-----
php[0-9]+.[0-9]+-cli 

php[0-9]+.[0-9]+-fpm 

php[0-9]+.[0-9]+-curl

php[0-9]+.[0-9]+-gd 

php[0-9]+.[0-9]+-mysql 

php[0-9]+.[0-9]+-mbstring


MYSQL
-----
mysql-server 
mysql-client

NINGX
-----
ningx

ZIP & UNZIP
-----------
zip
unzip

WORDPRESS
---------
WORDPRESS_ZIP=http://wordpress.org/latest.zip
WORDPRESS_TAR=https://wordpress.org/latest.tar.gz

Instructions
-------------
1. Download example.com and wordpress.sh files to a target machine
2. User should have permissions and ownership of both files e.g use sudo chown 'user'.'user' wordpress.sh example.com command for ownership
3. Run wordpress.sh using bash wordpress.sh or make it executable: chmod +x wordpress.sh and then run wordpress.sh
