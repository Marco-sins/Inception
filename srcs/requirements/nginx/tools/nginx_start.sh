#!/bin/bash
set -Eeuo pipefail

if [ ! -f /etc/ssl/certs/nginx.crt ] || [ ! -f /etc/ssl/private/nginx.key ];
then
    echo "Nginx: setting up TLS certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj "/C=ES/ST=Barcelona/O=Inception/CN=mmembril.42.fr"
fi

exec "$@"