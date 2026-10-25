#!/bin/sh
set -eu

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
    fresh=1
else
    fresh=0
fi

mariadbd --user=mysql --skip-networking &
pid=$!
ready=0

for _ in $(seq 1 30); do
    if mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent; then
        ready=1
        break
    fi
    sleep 1
done
if [ "$ready" -eq 0 ]; then
    echo "MariaDB did not start" >&2
    kill "$pid" 2>/dev/null || true
    exit 1
fi

if [ "$fresh" -eq 1 ]; then
    mariadb --socket=/run/mysqld/mysqld.sock <<-SQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
SQL
else
    mariadb -uroot -p"${MYSQL_ROOT_PASSWORD}" --socket=/run/mysqld/mysqld.sock <<-SQL
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
SQL
fi

mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid"
exec mariadbd --user=mysql
