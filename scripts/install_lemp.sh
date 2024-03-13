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

#-------------------#
# php-fpm permite mejorar el consumo de memoria con mucho tráfico, este se ejecutará como un servicio independiente de Nginx.
# php-mysql permite a php interar con el sistema gestor de base de datos.
#-------------------#

# Copiamos el contenido de default de default a /etc/nginx/sites-available/
cp ../conf/default /etc/nginx/sites-available/default

# Reiniciamos el servicio de nginx
systemctl restart nginx

# Damos permisos al usuario de nginx
chown -R www-data:www-data /var/www/html

# Copiamos el contenido de php a html para comprobar que funciona.
cp ../php/info.php /var/www/html