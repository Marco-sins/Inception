#!/bin/sh
set -eu
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/nginx/ssl/inception.key -out /etc/nginx/ssl/inception.crt \
        -subj "/CN=${DOMAIN_NAME}"
fi
exec nginx -g "daemon off;"
