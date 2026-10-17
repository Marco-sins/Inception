# Inception - guía de uso

## Requisitos

La máquina virtual debe tener Docker, Docker Compose y `make`. El usuario debe
tener permisos para ejecutar Docker.

## Ejecutar

Desde la raíz del proyecto:

```bash
make
```

El primer `make` crea automáticamente `.env`, los directorios persistentes y
la entrada del dominio en `/etc/hosts`. Solo pedirá la contraseña de `sudo`.
El usuario debe tener permisos para ejecutar Docker.

Abrir en el navegador:

```text
https://mmembril.42.fr
```

El certificado puede ser autofirmado. Para consultar el estado y los logs:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs
```

Detener los contenedores sin borrar los datos:

```bash
make down
```
