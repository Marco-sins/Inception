# Inception - guía de uso

## Requisitos

La máquina virtual debe tener Docker, Docker Compose y `make`. El usuario debe
tener permisos para ejecutar Docker.

## Preparación

Añadir el dominio local:

```bash
echo "127.0.0.1 mmembril.42.fr" | sudo tee -a /etc/hosts
```

Crear los directorios persistentes:

```bash
sudo mkdir -p /home/mmembril/data/mysql
sudo mkdir -p /home/mmembril/data/wordpress
```

Crear y editar las variables de entorno:

```bash
cp srcs/env.txt srcs/.env
chmod 600 srcs/.env
```

Configurar en `srcs/.env` el dominio, las contraseñas y los usuarios. El
administrador no puede llamarse `admin` ni contener `admin`. No subir este
archivo a Git.

## Ejecutar

Desde la raíz del proyecto:

```bash
make
```

Abrir en el navegador:

```text
https://mmembril.42.fr
```

El certificado puede ser autofirmado. Para consultar el estado y los logs:

```bash
docker-compose -f srcs/docker-compose.yml ps
docker-compose -f srcs/docker-compose.yml logs
```

Detener los contenedores sin borrar los datos:

```bash
make down
```
