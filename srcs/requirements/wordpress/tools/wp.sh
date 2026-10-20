
#!/bin/bash
set -Eeuo pipefail

echo "Esperando a MariaDB..."

for attempt in $(seq 1 60); do
    if mariadb -h"${MYSQL_HOSTNAME}" \
        -u"${MYSQL_USER}" \
        -p"${MYSQL_PASSWORD}" \
        -e "SELECT 1" >/dev/null 2>&1; then
        echo "MariaDB está lista."
        break
    fi

    if [ "$attempt" -eq 60 ]; then
        echo "Error: MariaDB no está disponible o las credenciales son incorrectas." >&2
        exit 1
    fi

    sleep 2
done

cd /var/www/html

if [ -f wp-config.php ]; then
    echo "WordPress ya está instalado."
else
    wp core download --allow-root

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOSTNAME}" \
        --allow-root

    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN}" \
        --admin_password="${WORDPRESS_ADMIN_PASS}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create "${WORDPRESS_USER}" "${WORDPRESS_EMAIL}" \
        --role=author \
        --user_pass="${WORDPRESS_USER_PASS}" \
        --allow-root

    wp theme install twentysixteen --activate --allow-root
fi

exec /usr/sbin/php-fpm8.2 -F
