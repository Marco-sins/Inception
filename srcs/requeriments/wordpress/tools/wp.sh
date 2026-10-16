#!/bin/bash

echo "Waiting MariaDB..."
while ! mariadb -h$MYSQL_HOSTNAME -u$MYSQL_USER -p$MYSQL_PASSWORD -e "Select 1;" >/dv/null 2>&1; do
    sleep 2
done
echo "MariaDB up."

if [ -f ./wp-config.php ]
then
    echo "Wordpress already exists."
else
    wp core download --allow-root
	wp config create --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER --dbpass=$MYSQL_PASSWORD --dbhost=$MYSQL_HOSTNAME --allow-root
	wp core install --url=$DOMAIN_NAME --title="$WORDPRESS_TITLE" --admin_user=$WORDPRESS_ADMIN --admin_password=$WORDPRESS_ADMIN_PASS  --admin_email=$WORDPRESS_ADMIN_EMAIL --skip-email --allow-root
	wp user create $WORDPRESS_USER $WORDPRESS_EMAIL --role=author --user_pass=$WORDPRESS_USER_PASS --allow-root
	wp theme install twentysixteen --activate --allow-root
fi

/usr/sbin/php-fpm8.2 -F;