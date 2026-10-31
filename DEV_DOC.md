# Inception - Documentación para desarrolladores

## Requisitos previos y configuración

Utiliza una máquina virtual Linux con Docker Engine, con el comando `docker-compose`, y `make`. El repositorio está estructurado de la siguiente manera:

```text
srcs/
  docker-compose.yml
  .env.example
  requirements/
    nginx/
    wordpress/
    mariadb/
```

Crea la configuración local y sustituye todos los valores de ejemplo:

```sh
cp srcs/.env.example srcs/.env
nano srcs/.env
```

`srcs/.env` está excluido de Git. Es el único archivo de configuración local que contiene contraseñas. Cada servicio tiene su propio Dockerfile y no utiliza imágenes preconstruidas de WordPress, NGINX o MariaDB.

## Construcción y lanzamiento

El flujo de trabajo habitual es:

```sh
make
```

El Makefile crea los directorios `$HOME/data/database` y `$HOME/data/html` y, a continuación, permite que Docker Compose construya e inicie los servicios. Compose crea la red puente `inception` y espera a que MariaDB supere su comprobación de estado (`healthcheck`) antes de iniciar WordPress.

Esto no utiliza `sudo` ni modifica `/etc/hosts`; añade el dominio local manualmente cuando sea necesario.

Antes de iniciar los servicios, `make` elimina los contenedores antiguos mediante `down --remove-orphans`. Esto conserva los volúmenes con nombre y evita un error conocido de recreación de Docker Compose v1 (`KeyError: ContainerConfig`).

Para validar el archivo Compose generado sin iniciar los contenedores:

```sh
docker compose -f srcs/docker-compose.yml config
```

Cuando Docker se ejecuta dentro de una máquina virtual, el puerto 443 se publica desde la propia máquina virtual.

Para acceder desde el navegador del equipo anfitrión, utiliza un adaptador de red en modo puente o solo-anfitrión y asigna la dirección IP de la máquina virtual al dominio `mmembril.42.fr` en el archivo `/etc/hosts` del equipo anfitrión, o configura un reenvío de puertos NAT desde el puerto 443 del anfitrión al puerto 443 de la máquina virtual.

`127.0.0.1` hace referencia a la propia máquina virtual cuando se utiliza dentro de ella, y no al ordenador anfitrión.

## Gestión de contenedores y volúmenes

```sh
make ps
make logs
make down
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up -d
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --allow-root
docker volume ls
```

El Makefile muestra una captura limitada de los registros en lugar de utilizar `logs -f`. Esto evita la excepción conocida `KeyError: 'id'` del flujo de eventos en la versión antigua de `docker-compose` v1. Los contenedores de la aplicación no se ven afectados por esta excepción del cliente.

`make clean` detiene los servicios, elimina las imágenes construidas localmente y los volúmenes, y borra el directorio de datos persistentes. Utilízalo únicamente cuando se puedan descartar todos los datos del sitio web.

## Persistencia y detalles de ejecución

Los volúmenes con nombre son `database` y `html`. Su controlador local almacena los datos en:

- `$HOME/data/database` para MariaDB.
- `$HOME/data/html` para los archivos de WordPress.

El directorio base de los montajes enlazados (*bind mounts*) puede modificarse mediante `DATA_DIR`. Las ejecuciones directas de Compose utilizan por defecto `/home/mmembril/data` para mantener la compatibilidad con el entorno de evaluación.

Los servicios se comunican a través de la red puente definida por el usuario `inception`. El DNS de Compose resuelve `mariadb` y `wordpress` hacia sus respectivos contenedores.

El `healthcheck` de MariaDB controla el inicio de WordPress. WordPress valida su configuración de PHP-FPM antes de ejecutarse en primer plano.

MariaDB inicializa automáticamente su base de datos y su usuario de aplicación en cada inicio del contenedor, incluso cuando el directorio de datos persistentes ya existe. Su `healthcheck` comprueba las credenciales de la aplicación y la base de datos, no simplemente que el proceso de MariaDB esté en ejecución.

WordPress copia sus archivos de origen al volumen, crea `wp-config.php`, instala el sitio y crea el segundo usuario durante la primera ejecución.

NGINX genera un certificado autofirmado y se ejecuta en primer plano como PID 1.

Únicamente NGINX publica el puerto 443. WordPress PHP-FPM escucha en el puerto 9000 dentro de la red privada de Docker y MariaDB no publica ningún puerto al equipo anfitrión.