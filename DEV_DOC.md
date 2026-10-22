# Inception - Developer documentation

## Prerequisites and setup

Use a Linux virtual machine with Docker Engine, either the Docker Compose
plugin or the `docker-compose` command, and `make`. The repository is
structured as follows:

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

The Makefile creates `/home/mmembril/data/database` and
`/home/mmembril/data/html`, then lets Docker Compose build and start the
services. Compose creates the `inception` bridge network and waits for
MariaDB's healthcheck before starting WordPress. This does not use `sudo` or
modify `/etc/hosts`; add the local
domain manually when necessary. Before starting, `make` removes old
containers with `down --remove-orphans`; this keeps named volumes and avoids a
known Docker Compose v1 recreation error (`KeyError: ContainerConfig`).
Validate the rendered Compose file without starting containers:

```sh
docker compose -f srcs/docker-compose.yml config
```

When Docker runs inside a virtual machine, port 443 is published by the VM.
For browser access from the host, use a bridged or host-only VM adapter and
map the VM address to `mmembril.42.fr` in the host's `/etc/hosts`, or configure
a NAT port forward from host port 443 to guest port 443. `127.0.0.1` refers to
the VM itself when used inside the VM and does not refer to the host computer.

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

The Makefile prints a bounded log snapshot instead of using `logs -f`. This
avoids the known `KeyError: 'id'` event-stream exception in legacy
`docker-compose` v1. The application containers are unaffected by that client
exception.

`make clean` stops the stack, removes locally built images and volumes, and
deletes the persistent data directory. Use it only when all site data may be
discarded.

## Persistence and runtime details

The named volumes are `database` and `html`. Their local
driver stores data at:

- `/home/mmembril/data/database` for MariaDB.
- `/home/mmembril/data/html` for WordPress files.

The services communicate through the user-defined `inception` bridge network;
Compose DNS resolves `mariadb` and `wordpress` to the corresponding
containers. The `mariadb` healthcheck gates WordPress startup. WordPress validates its
PHP-FPM configuration before running in the foreground. MariaDB initializes its
database and application user automatically at every container start, including
when the persistent data directory already exists. Its healthcheck tests the
application credentials and database, not merely the MariaDB process.
WordPress copies its source into the volume, creates `wp-config.php`, installs
the site, and creates the second user on the first run. NGINX generates a
self-signed certificate and runs in the foreground as PID 1.

Only NGINX publishes port 443. WordPress PHP-FPM listens on the private Docker
network at port 9000 and MariaDB is not published to the host.
