# Inception - evaluation study guide

This document is a practical study guide for defending the mandatory part of
the Inception project. It is not a replacement for understanding the source
code: during the evaluation, explain what each command and service does.

## 1. Preliminary checks

### Repository and required files

The repository must contain:

```text
Makefile
README.md
USER_DOC.md
DEV_DOC.md
srcs/
  docker-compose.yml
  .env
  requirements/
    nginx/Dockerfile
    wordpress/Dockerfile
    mariadb/Dockerfile
```

The real `srcs/.env` is created locally and ignored by Git. Never commit
passwords, API keys, certificates, or private keys. The tracked
`srcs/.env.example` contains placeholders only.

Before an evaluation, check that no secret is tracked:

```sh
git ls-files | grep -E '(^|/)(\.env|.*secret.*|.*credential.*)$' || true
git grep -nE 'PASSWORD=|PASS=|API_KEY=|PRIVATE KEY' -- ':!srcs/.env.example' || true
```

The evaluator and the student must both be present. If a requirement is
unclear, ask the evaluated student to demonstrate it rather than guessing.

### Clean Docker state

The subject proposes cleaning Docker before evaluating. This is destructive:
it removes all local containers, images, volumes, and networks, not only this
project. Run it only on a dedicated evaluation machine:

```sh
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q) 2>/dev/null
```

## 2. General static checks

Run these checks from the repository root:

```sh
test -f Makefile
test -d srcs
find srcs -name Dockerfile -print
docker compose -f srcs/docker-compose.yml config
```

The Compose file must contain a user-defined network and must not contain
`network: host`, `links:`, or `--link`:

```sh
grep -nE 'networks:|network_mode:|links:|--link|host' \
  srcs/docker-compose.yml Makefile srcs/requirements || true
```

Review every Dockerfile and script:

```sh
grep -RniE 'tail[[:space:]]+-f|sleep infinity|while[[:space:]]+true|bash$|sh$' \
  srcs/requirements Makefile || true
```

An entrypoint script may use `#!/bin/sh`, but it must run a real foreground
daemon with `exec`; it must not keep a container alive with an infinite loop.
The project uses:

```text
NGINX      -> nginx -g "daemon off;"
WordPress  -> php-fpm8.2 -F
MariaDB    -> mariadbd --user=mysql
```

## 3. Concepts to explain

### Docker and Docker Compose

Docker packages an application and its dependencies in an image. A container
is a running instance of an image with an isolated filesystem, processes,
network namespace, and resource configuration. Containers share the host
kernel, so they are lighter than virtual machines.

Docker Compose is the declarative orchestration layer. The YAML file defines
services, builds, networks, volumes, dependencies, environment variables, and
published ports. Compose creates the resources and gives services DNS names
matching their service names.

### Image with and without Compose

Without Compose, each image/container must be built and started manually:

```sh
docker build -t nginx:1.26 srcs/requirements/nginx
docker run --name nginx_inception -p 443:443 ...
```

With Compose, the same configuration is reproducible:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

Compose does not change what an image is. It automates the relationship
between several containers and keeps their configuration in one place.

### Docker versus virtual machines

Docker containers start quickly, use fewer resources, and share the host
kernel. A virtual machine contains a complete guest operating system and
kernel, so it generally uses more RAM and disk but provides stronger
isolation. This project uses a VM as required by the subject and Docker inside
that VM for the services.

### Docker network

`inception` is a user-defined bridge network. Containers attached to it can
resolve service names through Docker DNS:

```text
wordpress -> mariadb:3306
nginx     -> wordpress:9000
```

The database and PHP-FPM ports are not published on the host. Only NGINX is
published on port 443.

### Docker volumes

The project has two named volumes:

```text
html      -> /home/mmembril/data/html
database  -> /home/mmembril/data/database
```

The local volume driver binds these host directories while the application
uses Docker volume names. This keeps WordPress files and the MariaDB database
outside the disposable container layers.

## 4. Start and inspect the project

Create local configuration from the example and replace placeholders:

```sh
cp srcs/.env.example srcs/.env
$EDITOR srcs/.env
```

The administrator username must not contain `admin` or `administrator`.
The administrator and normal WordPress user must use different email
addresses.

Start the mandatory stack:

```sh
make
```

The Makefile prepares the persistent directories and runs Docker Compose. A
successful run must not end with a Make error.

Inspect services:

```sh
docker compose -f srcs/docker-compose.yml ps
docker ps
docker compose -f srcs/docker-compose.yml logs --tail=100
```

The expected containers are:

```text
nginx_inception
wordpress_inception
db_inception
```

The expected state is that all three are running and MariaDB is healthy.

If the VM only provides Compose v1, use `docker-compose` consistently in the
commands above. The project Makefile detects either `docker compose` or
`docker-compose`.

## 5. NGINX and TLS checks

Only NGINX publishes port 443:

```sh
docker compose -f srcs/docker-compose.yml ps
ss -lnt | grep ':443'
```

The expected published port is:

```text
0.0.0.0:443->443/tcp
```

Port 80 must not be open:

```sh
curl -I http://mmembril.42.fr
```

The HTTPS request must work. Because the certificate is self-signed, `-k` is
used for testing:

```sh
curl -k -I https://mmembril.42.fr
curl -k -I https://mmembril.42.fr:443
```

Port `433` is not the HTTPS port; `443` is.

Check the enabled protocols:

```sh
docker exec nginx_inception nginx -T 2>/dev/null | grep ssl_protocols
```

The result must contain only:

```text
ssl_protocols TLSv1.2 TLSv1.3;
```

The browser URL is:

```text
https://mmembril.42.fr
```

If the browser runs on the host while Docker runs in a VM, put the VM IP in
the host's `/etc/hosts`, for example:

```text
172.16.47.132 mmembril.42.fr
```

Use `127.0.0.1` only when the browser runs inside the VM.

## 6. WordPress and PHP-FPM checks

The WordPress Dockerfile must install PHP-FPM and must not install NGINX:

```sh
grep -nE 'FROM|php.*fpm|nginx' srcs/requirements/wordpress/Dockerfile
docker exec wordpress_inception php-fpm8.2 -t
```

Check that PHP-FPM listens on the private network port:

```sh
docker exec wordpress_inception sh -c \
  "grep -E '^listen[[:space:]]*=' /etc/php/8.2/fpm/pool.d/www.conf"
```

Expected:

```text
listen = 0.0.0.0:9000
```

The site must be installed, not show the WordPress installation screen:

```sh
docker exec wordpress_inception wp core is-installed --allow-root
docker exec wordpress_inception wp user list --allow-root
```

There must be two users. The administrator username must not include
`admin`/`Admin` or `administrator`/`Administrator`.

From the browser:

1. Open `https://mmembril.42.fr`.
2. Log in at `https://mmembril.42.fr/wp-admin`.
3. Create or edit a page.
4. Publish it.
5. Open the page as a visitor and verify the change.
6. Add a comment with the normal WordPress user and verify it.

## 7. MariaDB and database checks

MariaDB must have its own Dockerfile and must not contain NGINX:

```sh
grep -nE 'FROM|nginx' srcs/requirements/mariadb/Dockerfile
```

Check the database volume:

```sh
docker volume ls
docker volume inspect database
```

The inspection must show the required host path:

```text
/home/mmembril/data/database
```

Connect using the credentials in the local, ignored `srcs/.env`:

```sh
set -a
. srcs/.env
set +a
docker exec -it db_inception \
  mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
```

Inside the container, the variables are available through Compose. A direct
example using the values from `.env` is:

```sh
docker exec -it db_inception \
  mariadb -uwordpress_user -ppassdb wordpress
```

Do not put real credentials in this document or in Git. The database should
contain WordPress tables:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT ID, user_login, user_email FROM wp_users;
```

The exact table prefix can differ; inspect `wp-config.php` if necessary.

## 8. Persistence test

Make a visible change in WordPress first, then restart the VM or at least the
Docker services:

```sh
docker compose -f srcs/docker-compose.yml down
make
```

After startup, verify:

```sh
docker compose -f srcs/docker-compose.yml ps
docker volume inspect html
docker volume inspect database
```

The edited page, users, comments, and database tables must still exist. The
host directories must contain data:

```sh
find /home/mmembril/data/html -maxdepth 2 -type f | head
find /home/mmembril/data/database -maxdepth 2 -type f | head
```

Do not use `make clean` for this test: it intentionally removes the persistent
data.

## 9. Mandatory checklist

Before the defense, confirm every item:

- [ ] `Makefile` is at the repository root.
- [ ] All application files are under `srcs/`.
- [ ] `srcs/.env` is local and ignored.
- [ ] No password is in a Dockerfile or tracked file.
- [ ] One custom Dockerfile exists for each service.
- [ ] Each Dockerfile starts from Debian or Alpine.
- [ ] Images are built locally and use explicit non-`latest` tags.
- [ ] Three dedicated containers run.
- [ ] The user-defined `inception` network is present.
- [ ] No `host` network, `links`, or `--link` is used.
- [ ] No infinite loop, `tail -f`, or `sleep infinity` is used.
- [ ] Only NGINX publishes port 443.
- [ ] Port 80 is not exposed.
- [ ] TLS is restricted to 1.2 and 1.3.
- [ ] WordPress uses PHP-FPM and contains no NGINX.
- [ ] MariaDB contains no NGINX.
- [ ] WordPress is already installed.
- [ ] There are two WordPress users.
- [ ] The administrator name contains neither `admin` nor `administrator`.
- [ ] MariaDB has a non-empty WordPress database.
- [ ] The two named volumes persist under `/home/mmembril/data/`.
- [ ] A page edit and a comment can be verified.
- [ ] Data survives a restart.

The mandatory part is complete without adding the bonus services such as FTP,
Redis, Adminer, or Portainer.
