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