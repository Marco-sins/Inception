#!/bin/bash
set -Eeuo pipefail

: "${MYSQL_HOSTNAME:?MYSQL_HOSTNAME is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${WORDPRESS_TITLE:?WORDPRESS_TITLE is required}"
: "${WORDPRESS_ADMIN:?WORDPRESS_ADMIN is required}"
: "${WORDPRESS_ADMIN_PASS:?WORDPRESS_ADMIN_PASS is required}"
: "${WORDPRESS_ADMIN_EMAIL:?WORDPRESS_ADMIN_EMAIL is required}"
: "${WORDPRESS_USER:?WORDPRESS_USER is required}"
: "${WORDPRESS_EMAIL:?WORDPRESS_EMAIL is required}"
: "${WORDPRESS_USER_PASS:?WORDPRESS_USER_PASS is required}"

chown -R www-data:www-data /var/www/html
echo "Waiting for MariaDB..."
for attempt in $(seq 1 60); do
    if mariadb -h"$MYSQL_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        -e "SELECT 1" >/dev/null 2>&1; then
        break
    fi
    if [ "$attempt" -eq 60 ]; then
        echo "MariaDB did not become available" >&2
        exit 1
    fi
    sleep 2
done

if [ ! -f wp-config.php ]; then
    wp core download --allow-root
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOSTNAME" \
        --allow-root
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN" \
        --admin_password="$WORDPRESS_ADMIN_PASS" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
    wp user create "$WORDPRESS_USER" "$WORDPRESS_EMAIL" \
        --role=author \
        --user_pass="$WORDPRESS_USER_PASS" \
        --allow-root
    wp theme install twentysixteen --activate --allow-root
fi

exec /usr/sbin/php-fpm8.2 -F
