#!/bin/bash

apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql wget

cd /var/www/html
rm index.html
wget https://ja.wordpress.org/latest-ja.tar.gz
tar -xzvf latest-ja.tar.gz
mv wordpress/* .
rmdir wordpress
rm latest-ja.tar.gz

chown -R www-data:www-data /var/www/html

systemctl start apache2
systemctl enable apache2