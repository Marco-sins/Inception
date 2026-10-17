#!/bin/bash
set -Eeuo pipefail

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_ROOT_USER:?MYSQL_ROOT_USER is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

chown -R mysql:mysql /var/lib/mysql
service mariadb start

for attempt in $(seq 1 30); do
    if mariadb-admin --protocol=socket ping --silent; then
        break
    fi
    if [ "$attempt" -eq 30 ]; then
        echo "MariaDB did not become ready" >&2
        exit 1
    fi
    sleep 1
done

if mariadb -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
    echo "MariaDB is already configured."
else
    mariadb -u"$MYSQL_ROOT_USER" <<SQL
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
ALTER USER '$MYSQL_ROOT_USER'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
SQL
fi

mariadb-admin -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" shutdown
exec mysqld --user=mysql --console
