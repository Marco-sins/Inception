# Inception - Developer documentation

## Prerequisites and setup

Use a Linux virtual machine with Docker Engine, the Docker Compose plugin,
`make`, and `sudo`. The repository is structured as follows:

```text
srcs/
  docker-compose.yml
  .env.example
  requirements/
    nginx/
    wordpress/
    mariadb/
```

Create the local configuration and replace every placeholder:

```sh
cp srcs/.env.example srcs/.env
$EDITOR srcs/.env
```

`srcs/.env` is ignored by Git. It is the only local configuration file
containing passwords. Each service has its own Dockerfile and does not use a
pre-built WordPress, NGINX, or MariaDB image.

## Build and launch

The normal workflow is:

```sh
make
```

The Makefile creates `/home/mmembril/data/mysql` and
`/home/mmembril/data/wordpress`, ensures the local domain is mapped, and runs
`docker compose up -d --build`. Validate the rendered Compose file without
starting containers:

```sh
docker compose -f srcs/docker-compose.yml config
```

## Container and volume management

```sh
make ps
make logs
make down
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up -d
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --allow-root
docker volume ls
```

`make clean` stops the stack, removes locally built images and volumes, and
deletes the persistent data directory. Use it only when all site data may be
discarded.

## Persistence and runtime details

The named volumes are `inception_mariadb` and `inception_wordpress`. Their local
driver stores data at:

- `/home/mmembril/data/mysql` for MariaDB.
- `/home/mmembril/data/wordpress` for WordPress files.

The `mariadb` healthcheck gates WordPress startup. MariaDB initializes its
database and application user only when the data directory is empty.
WordPress copies its source into the volume, creates `wp-config.php`, installs
the site, and creates the second user on the first run. NGINX generates a
self-signed certificate and runs in the foreground as PID 1.

Only NGINX publishes port 443. WordPress PHP-FPM listens on the private Docker
network at port 9000 and MariaDB is not published to the host.
