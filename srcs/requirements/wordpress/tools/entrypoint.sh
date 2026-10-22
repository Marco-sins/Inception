#!/bin/sh
set -eu
if [ ! -f /var/www/html/wp-includes/version.php ]; then cp -a /usr/src/wordpress/. /var/www/html/; fi
chown -R www-data:www-data /var/www/html
if [ ! -f /var/www/html/wp-config.php ]; then
    wp config create --path=/var/www/html --dbname="$MYSQL_DATABASE" --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" --dbhost=mariadb --skip-check --allow-root
else
    wp config set DB_NAME "$MYSQL_DATABASE" --path=/var/www/html --allow-root
    wp config set DB_USER "$MYSQL_USER" --path=/var/www/html --allow-root
    wp config set DB_PASSWORD "$MYSQL_PASSWORD" --path=/var/www/html --allow-root
    wp config set DB_HOST mariadb --path=/var/www/html --allow-root
fi

ready=0
for _ in $(seq 1 60); do
    if php -r '
        $connection = @mysqli_connect(
            getenv("MYSQL_HOSTNAME") ?: "mariadb",
            getenv("MYSQL_USER"),
            getenv("MYSQL_PASSWORD"),
            getenv("MYSQL_DATABASE"),
            3306
        );
        if ($connection) {
            mysqli_close($connection);
            exit(0);
        }
        exit(1);
    '; then
        ready=1
        break
    fi
    sleep 1
done
if [ "$ready" -ne 1 ]; then
    echo "WordPress could not connect to MariaDB at mariadb:3306 after 60 seconds" >&2
    exit 1
fi

if ! wp core is-installed --path=/var/www/html --allow-root >/dev/null 2>&1; then
    wp core install --path=/var/www/html --url="https://${DOMAIN_NAME}" \
        --title="$WORDPRESS_TITLE" --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email --allow-root
fi

if ! wp user get "$WORDPRESS_USER" --path=/var/www/html --allow-root >/dev/null 2>&1; then
    if wp user list --field=user_email --path=/var/www/html --allow-root | grep -Fxq "$WORDPRESS_USER_EMAIL"; then
        echo "WordPress user email is already in use: ${WORDPRESS_USER_EMAIL}" >&2
        echo "Set WORDPRESS_USER_EMAIL to a different address in srcs/.env" >&2
        exit 1
    fi
    wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
        --user_pass="$WORDPRESS_USER_PASSWORD" --role=author --path=/var/www/html --allow-root
fi

php-fpm8.2 -t
exec php-fpm8.2 -F
