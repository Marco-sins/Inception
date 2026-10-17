#!/bin/bash

if [ ! -f /etc/ssl/certs/nginx.crt ];
then
    echo "Nginx: Setting up ssl...";
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/nginx.key -out /etc/ssl/certs/nginx.crt -subj "/C=ES/ST=Barcelona/=wordpress/CN=mmembril.42.fr";
    echo "Nginx: ssl is set up!";
fi
exec "$@"