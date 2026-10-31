# Inception - Documentación para usuarios

## Servicios

La infraestructura proporciona un sitio web de WordPress mediante HTTPS:

- NGINX termina la conexión TLS en el puerto 443 y reenvía las solicitudes PHP.
- WordPress ejecuta PHP-FPM y proporciona el sitio web y el panel `/wp-admin`.
- MariaDB almacena el contenido y la configuración de WordPress.

## Iniciar y detener

Instala Docker, Docker Compose y `make`. A continuación, ejecuta desde la raíz del repositorio:

```sh
make
```

Para detener los contenedores conservando los datos:

```sh
make down
```

Para consultar el estado de los contenedores y sus registros:

```sh
make ps
make logs
```

`make logs` muestra las últimas 100 líneas sin seguir el flujo de registros. Esto es intencionado porque el cliente antiguo `docker-compose` v1 puede generar un error `KeyError: 'id'` al seguir los eventos de Docker Engine.

Utiliza `docker compose logs -f` únicamente cuando esté instalado el complemento Compose v2.

## Sitio web y administración

Obtén la dirección IP de la máquina virtual con:

```sh
ip -4 addr show
```

Añade `127.0.0.1 mmembril.42.fr` al archivo `/etc/hosts` de la máquina virtual.

Accede a:

- Sitio web: `https://mmembril.42.fr`
- Administración: `https://mmembril.42.fr/wp-admin`

El certificado está autofirmado, por lo que es normal que el navegador muestre una advertencia durante el primer acceso.

## Credenciales

Durante la primera ejecución, `make` copia `srcs/.env.example` a `srcs/.env`.

Edita `srcs/.env` y sustituye todos los valores de ejemplo antes de iniciar los servicios.

Este archivo, que está excluido de Git, contiene las credenciales de root y de la base de datos de MariaDB, así como las credenciales de ambos usuarios de WordPress.

Nunca subas `srcs/.env` a Git, lo compartas públicamente ni introduzcas contraseñas en un Dockerfile.

Para un despliegue en producción, utiliza Docker Secrets u otro gestor de secretos.

## Solución de problemas

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Si el sitio web no está disponible inmediatamente, espera a que MariaDB y WordPress terminen su inicialización inicial.

Los datos persistentes se conservan al ejecutar `make down`.