#!/bin/sh
set -eu
if [ ! -f /var/www/html/wp-includes/version.php ]; then cp -a /usr/src/wordpress/. /var/www/html/; fi
chown -R www-data:www-data /var/www/html
if [ ! -f /var/www/html/wp-config.php ]; then
    wp config create --path=/var/www/html --dbname="$MYSQL_DATABASE" --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" --dbhost=mariadb --skip-check --allow-root
fi
if ! wp core is-installed --path=/var/www/html --allow-root >/dev/null 2>&1; then
    wp core install --path=/var/www/html --url="https://${DOMAIN_NAME}" \
        --title="$WORDPRESS_TITLE" --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email --allow-root
    wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
        --user_pass="$WORDPRESS_USER_PASSWORD" --role=author --path=/var/www/html --allow-root
fi
exec php-fpm8.2 -F
