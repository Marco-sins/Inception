# Inception - User documentation

## Services

The stack provides a WordPress website over HTTPS:

- NGINX terminates TLS on port 443 and forwards PHP requests.
- WordPress runs PHP-FPM and provides the website and `/wp-admin` panel.
- MariaDB stores WordPress content and settings.

## Start and stop

Install Docker, Docker Compose, and `make`, then run from the repository root:

```sh
make
```

To stop containers while keeping data:

```sh
make down
```

To see container status and logs:

```sh
make ps
make logs
```

`make logs` shows the latest 100 lines without following the stream. This is
intentional because the legacy `docker-compose` v1 client can raise a
`KeyError: 'id'` while following Docker Engine events. Use
`docker compose logs -f` only when the Compose v2 plugin is installed.

## Website and administration

Find the VM address with:

```sh
ip -4 addr show
```

If the browser runs inside the VM, add `127.0.0.1 mmembril.42.fr` to the VM's
`/etc/hosts`. If the browser runs on the host computer, add the VM's address
instead, for example `192.168.56.101 mmembril.42.fr`, to the host computer's
`/etc/hosts`. The VM network adapter must be reachable from the host
(bridged networking or a host-only adapter), or port 443 must be forwarded
from the host to the VM.

Visit:

- Website: `https://mmembril.42.fr`
- Administration: `https://mmembril.42.fr/wp-admin`

The certificate is self-signed, so a browser warning on first access is
expected.

## Credentials

On the first run, `make` copies `srcs/.env.example` to `srcs/.env`. Edit
`srcs/.env` and replace all placeholder values before starting. This ignored
file contains the MariaDB root/database credentials and both WordPress user
credentials. The administrator username is deliberately `mmembril_manager`
and does not contain `admin`.

Never commit `srcs/.env`, share it publicly, or put passwords in a Dockerfile.
For a production deployment, use Docker secrets or another secret manager.

## Troubleshooting

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

If the site is not ready immediately, wait for MariaDB and WordPress to finish
their first-time initialization. Persistent data is retained by `make down`.
