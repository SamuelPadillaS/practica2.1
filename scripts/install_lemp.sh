#!/bin/bash

# Mostrar vervose
set -ex

# Incorporamos variables.
source .env

# Actualizamos los repositorios.
apt update

# Instalamos nginx
apt install nginx -y

# Instalar mysqlserver
apt install mysql-server -y

# Instalacion de paquetes: paquete php-fpm y php-mysql
apt install php-fpm php-mysql -y

# Copiamos el contenido de default de default a /etc/nginx/sites-available/
cp ../conf/default /etc/nginx/sites-available/default

# Reiniciamos el servicio de nginx
systemctl restart nginx

# Damos permisos al usuario de nginx
chown -R www-data:www-data /var/www/html
