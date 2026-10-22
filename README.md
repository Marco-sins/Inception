*This project has been created as part of the 42 curriculum by mmembril.*

# Inception

## Description

Inception builds a small web infrastructure with Docker Compose. It contains
three services, each in its own custom Debian-based image:

- **NGINX** is the only public entry point and serves HTTPS on port 443.
- **WordPress** runs PHP-FPM and serves the website.
- **MariaDB** stores the WordPress database.

The services use the private Docker bridge network `mmembrilnet`. WordPress files and the
database are stored in two named volumes backed by `/home/mmembril/data`.
Only the mandatory part of the subject is implemented; the bonus services are
intentionally out of scope.

### Main design choices

Dockerfiles install and configure the software instead of using ready-made
application images. Compose passes all configuration through `srcs/.env`, and
the first `make` creates that file from the non-secret template
`srcs/.env.example`. NGINX creates a local self-signed certificate at startup,
so no private key is committed.

### Docker concepts compared

| Choice | This project | Alternative and trade-off |
| --- | --- | --- |
| Virtual machine vs Docker | Docker containers share the host kernel and start quickly with low overhead. | A VM includes a complete guest kernel and gives stronger isolation, but needs more resources. |
| Secrets vs environment variables | Environment variables in the ignored `.env` file keep the mandatory setup simple. | Docker secrets are safer for production because values are mounted as files and are not exposed in process environments; they are recommended for a deployment system. |
| Docker network vs host network | A user-defined bridge network provides service-name DNS and isolation. | Host networking removes network isolation and exposes services directly on the host, so it is not used. |
| Docker volumes vs bind mounts | Named volumes provide Docker-managed persistence while their local driver stores data in the required host directory. | A direct bind mount couples the container to a host path and is less portable. |

## Instructions

### Prerequisites

Use a Linux virtual machine with Docker Engine, either the Docker Compose
plugin or the `docker-compose` command, and `make`. Add the current user to
the `docker` group if needed.

### Start and stop

From the repository root:

```sh
make
make ps
make logs
make down
```

`make` creates the persistent directories, builds all images, and starts the
stack. The first run copies `srcs/.env.example` to the ignored `srcs/.env`;
replace every placeholder password before starting. When using a VM, map
`mmembril.42.fr` to the VM IP address in the `/etc/hosts` file of the machine
running the browser. Use `127.0.0.1` only when the browser runs inside the VM.

Open `https://mmembril.42.fr` and accept the warning for the self-signed
certificate. The administration panel is at `https://mmembril.42.fr/wp-admin`.
See [USER_DOC.md](./USER_DOC.md) for operational details and
[DEV_DOC.md](./DEV_DOC.md) for implementation details.

## Resources

- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)

AI was used to compare the repository with the mandatory Inception subject,
organize the Compose architecture, draft the initial documentation, and review
configuration consistency. The Dockerfiles, shell scripts, credentials setup,
and validation commands must be understood and verified by the project author.
