# Despliegue de WordPress utilizando una pila LEMP

En esta práctica tendremos que realizar la instalación de WordPress sobre una pila LEMP en una instancia EC2 de Amazon Web Services (AWS).

Tendrá que utilizar los scripts que diseñó en la práctica 1.7: “Administración de Wordpress con la utilidad WP-CLI” y adaptarlos para modificar el servidor web Apache por el servidor web Nginx.

Los cambios que tendrá que realizar son los siguientes:

- Crear el archivo install_lemp.sh para instalar y configurar el servidor web Nginx.
  
- Modificar el script setup_letsencrypt_https.sh para indicarle a certbot que estamos utilizando un servidor web Nginx.
  
- Configurar el servidor web Nginx para poder utilizar enlaces permanentes en WordPress. Tenga en cuenta que el servidor Nginx no utiliza archivos .htaccess para mejorar su rendimiento. Se recomienda la lectura de este artículo de la página oficial de Nginx donde explica brevemente esta cuestión.

Lo primero de todo sera indicar la estructura básica que seguira nuestra práctica

~~~
.
├── README.md
├── conf
    └── default
    └── .htaccess
└── scripts
    ├── .env
    ├── install_lemp.sh
    ├── setup_letsencrypt_https.sh
    └── deploy_wordpress_with_wpcli.sh
~~~

El contenido de cada uno de los archivos es el siguiente:

### /conf/default

~~~
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                index index.php index.html index.htm;
                try_files $uri $uri/ /index.php?$args;
        }

        # pass PHP scripts to FastCGI server
        #
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                # With php-fpm (or other unix sockets):
                fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }
}
~~~

### /conf/.htaccess

~~~
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
~~~

### /scripts/.env

~~~
# Variables para el certificado.
CERTIFICATE_EMAIL=demo@demo.es
CERTIFICATE_DOMAIN=practica21iaw.ddns.net


WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wp_user
WORDPRESS_DB_PASSWORD=wp_pass
IP_CLIENTE_MYSQL=localhost
WORDPRESS_DB_HOST=localhost
WORDPRESS_HIDE_LOGIN=samueladmin

wordpress_title="Sitio web de IAW"
wordpress_admin_user=admin
wordpress_admin_pass=admin
wordpress_admin_email=demo@demo.es
~~~

### /scripts/deploy_wordpress.sh

~~~
#!/bin/bash

set -ex

# Actualización de repositorios
apt update

# Actualización de paquetes
# sudo apt upgrade  

# Incluimos las variables del archivo .env.
source .env

# Borramos los archivos previos.
rm -rf /tmp/wp-cli.phar

# Descargamos La utilidad wp-cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Asignamos permisos de ejecución al archivo wp-cli.phar
chmod +x /tmp/wp-cli.phar

# Movemos los el fichero wp-cli.phar a bin para incluirlo en la lista de comandos.
mv /tmp/wp-cli.phar /usr/local/bin/wp

# Eliminamos instalaciones previas de wordpress
rm -rf /var/www/html/*

#Descargarmos el codigo fuente de wordpress en /var/www/html
wp core download --path=/var/www/html --locale=es_ES --allow-root

# Creamos la base de la bbase de datos y el usuario de la base de datos.
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creación del archivo wp-config 
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --path=/var/www/html \
  --allow-root

# Instalar wordpress.

wp core install \
  --url=$CERTIFICATE_DOMAIN \
  --title="$wordpress_title" \
  --admin_user=$wordpress_admin_user \
  --admin_password=$wordpress_admin_pass \
  --admin_email=$wordpress_admin_email \
  --path=/var/www/html \
  --allow-root

# Actualizamos el core
wp core update --path=/var/www/html --allow-root

# Instalamos un tema:

wp theme install sydney --activate --path=/var/www/html --allow-root

# Instalamos el plugin bbpress:

wp plugin install bbpress --activate --path=/var/www/html --allow-root

# Instalamos el plugin para ocultar wp-admin
wp plugin install wps-hide-login --activate --path=/var/www/html --allow-root

# Habilitar permalinks
wp rewrite structure '/%postname%/' \
  --path=/var/www/html \
  --allow-root
  
# Modificamos automaticamente el nombre que establece por defecto el plugin wpd-hide-login
wp option update whl_page $WORDPRESS_HIDE_LOGIN --path=/var/www/html --allow-root

# Copiamos el htaccess a /var/www/html
cp ../conf/.htaccess /var/www/html

# Cambiamos al propietario de /var/www/html como www-data
chown -R www-data:www-data /var/www/html
~~~

### install_lemp.sh

~~~
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
~~~

### setup_letsencrypt_certificate.sh

~~~
#!/bin/bash

# Muestra todos los comandos que se han ejeutado.

set -ex

# Actualización de repositorios
 apt update

# Actualización de paquetes
# sudo apt upgrade 

# Importamos el archivo de variables .env
source .env


# Borramos certbot para instalarlo despues, en caso de que se encuentre, lo borramos de apt para instalarlo con snap.
apt remove certbot

#Instalación de snap y actualizacion del mismo.
snap install core
snap refresh core

# Instalamos la aplicacion certbot
snap install --classic certbot

#Creamos un alias para la aplicacion certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

# Obtener el certificado.
certbot --nginx -m $CERTIFICATE_EMAIL --agree-tos --no-eff-email -d $CERTIFICATE_DOMAIN --non-interactive
~~~

Ya contodo creado solo nos quedaria ejecutar los comandos en el orden correspondiente:

- 1º. install_lemp.sh

- 2º. deploy_wordpress.sh

- 3º. setup_letsencrypt_certificate.sh
  
![Captura de pantalla 2024-06-16 184319](https://github.com/SamuelPadillaS/practica2.1/assets/114667075/a888b273-d4e4-4281-b6e8-a1f3a2db691b)

