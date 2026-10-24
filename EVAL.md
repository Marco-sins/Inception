# Inception - guía de estudio para la evaluación

Este documento es una guía práctica de estudio para defender la parte
obligatoria del proyecto Inception. No sustituye la comprensión del código
fuente: durante la evaluación, explica qué hace cada comando y servicio.

## 1. Comprobaciones preliminares

### Repositorio y archivos requeridos

El repositorio debe contener:

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

El `srcs/.env` real se crea localmente y Git lo ignora. Nunca subas
contraseñas, claves API, certificados o claves privadas. El archivo
`srcs/.env.example` versionado solo contiene marcadores de posición.

Antes de una evaluación, comprueba que no haya ningún secreto versionado:

```sh
git ls-files | grep -E '(^|/)(\.env|.*secret.*|.*credential.*)$' || true
git grep -nE 'PASSWORD=|PASS=|API_KEY=|PRIVATE KEY' -- ':!srcs/.env.example' || true
```

El evaluador y el estudiante deben estar presentes. Si un requisito no está
claro, pide al estudiante evaluado que lo demuestre en lugar de adivinar.

### Limpiar el estado de Docker

El tema propone limpiar Docker antes de evaluar. Esto es destructivo:
elimina todos los contenedores, imágenes, volúmenes y redes locales, no solo
los de este proyecto. Ejecútalo únicamente en una máquina dedicada a la evaluación:

```sh
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q) 2>/dev/null
```

## 2. Comprobaciones estáticas generales

Ejecuta estas comprobaciones desde la raíz del repositorio:

```sh
test -f Makefile
test -d srcs
find srcs -name Dockerfile -print
docker compose -f srcs/docker-compose.yml config
```

El archivo Compose debe contener una red definida por el usuario y no debe contener
`network: host`, `links:` o `--link`:

```sh
grep -nE 'networks:|network_mode:|links:|--link|host' \
  srcs/docker-compose.yml Makefile srcs/requirements || true
```

Revisa cada Dockerfile y script:

```sh
grep -RniE 'tail[[:space:]]+-f|sleep infinity|while[[:space:]]+true|bash$|sh$' \
  srcs/requirements Makefile || true
```

Un script de entrada puede usar `#!/bin/sh`, pero debe ejecutar un demonio
real en primer plano con `exec`; no debe mantener un contenedor activo con un
bucle infinito. El proyecto usa:

```text
NGINX      -> nginx -g "daemon off;"
WordPress  -> php-fpm8.2 -F
MariaDB    -> mariadbd --user=mysql
```

## 3. Conceptos que debes explicar

### Docker y Docker Compose

Docker empaqueta una aplicación y sus dependencias en una imagen. Un contenedor
es una instancia en ejecución de una imagen con un sistema de archivos,
procesos, espacio de nombres de red y configuración de recursos aislados. Los
contenedores comparten el kernel del host, por lo que son más ligeros que las
máquinas virtuales.

Docker Compose es la capa de orquestación declarativa. El archivo YAML define
servicios, compilaciones, redes, volúmenes, dependencias, variables de entorno
y puertos publicados. Compose crea los recursos y asigna a los servicios
nombres DNS que coinciden con sus nombres de servicio.

### Imagen con y sin Compose

Sin Compose, cada imagen/contenedor debe compilarse e iniciarse manualmente:

```sh
docker build -t nginx:1.0 srcs/requirements/nginx
docker run --name nginx -p 443:443 ...
```

Con Compose, la misma configuración es reproducible:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

Compose no cambia lo que es una imagen. Automatiza la relación entre varios
contenedores y mantiene su configuración en un solo lugar.

### Docker frente a máquinas virtuales

Los contenedores Docker se inician rápidamente, utilizan menos recursos y
comparten el kernel del host. Una máquina virtual contiene un sistema operativo
y un kernel invitados completos, por lo que generalmente usa más RAM y disco,
pero proporciona un aislamiento más fuerte. Este proyecto usa una VM como
requiere el tema y Docker dentro de esa VM para los servicios.

### Red de Docker

`inception` es una red puente definida por el usuario. Los contenedores
conectados a ella pueden resolver nombres de servicio mediante el DNS de Docker:

```text
wordpress -> mariadb:3306
nginx     -> wordpress:9000
```

Los puertos de la base de datos y PHP-FPM no se publican en el host. Solo
NGINX se publica en el puerto 443.

### Volúmenes de Docker

El proyecto tiene dos volúmenes con nombre:

```text
html      -> /home/mmembril/data/html
database  -> /home/mmembril/data/database
```

El controlador de volúmenes local vincula estos directorios del host mientras
la aplicación usa nombres de volúmenes Docker. Esto mantiene los archivos de
WordPress y la base de datos MariaDB fuera de las capas desechables del contenedor.

## 4. Iniciar e inspeccionar el proyecto

Crea la configuración local a partir del ejemplo y reemplaza los marcadores:

```sh
cp srcs/.env.example srcs/.env
$EDITOR srcs/.env
```

El nombre de usuario del administrador no debe contener `admin` ni
`administrator`. El administrador y el usuario normal de WordPress deben usar
direcciones de correo electrónico diferentes.

Inicia la pila obligatoria:

```sh
make
```

El Makefile prepara los directorios persistentes y ejecuta Docker Compose. Una
ejecución correcta no debe terminar con un error de Make.

Inspecciona los servicios:

```sh
docker compose -f srcs/docker-compose.yml ps
docker ps
docker compose -f srcs/docker-compose.yml logs --tail=100
```

Los contenedores esperados son:

```text
nginx
wordpress
mariadb
```

El estado esperado es que los tres estén en ejecución y MariaDB esté saludable.

Si la VM solo proporciona Compose v1, usa `docker-compose` de forma coherente
en los comandos anteriores. El Makefile del proyecto detecta tanto `docker compose`
como `docker-compose`.

## 5. Comprobaciones de NGINX y TLS

Solo NGINX publica el puerto 443:

```sh
docker compose -f srcs/docker-compose.yml ps
ss -lnt | grep ':443'
```

El puerto publicado esperado es:

```text
0.0.0.0:443->443/tcp
```

El puerto 80 no debe estar abierto:

```sh
curl -I http://mmembril.42.fr
```

La solicitud HTTPS debe funcionar. Como el certificado es autofirmado, se usa
`-k` para las pruebas:

```sh
curl -k -I https://mmembril.42.fr
curl -k -I https://mmembril.42.fr:443
```

El puerto `433` no es el puerto HTTPS; `443` sí lo es.

Comprueba los protocolos habilitados:

```sh
docker exec nginx nginx -T 2>/dev/null | grep ssl_protocols
```

El resultado debe contener únicamente:

```text
ssl_protocols TLSv1.2 TLSv1.3;
```

La URL del navegador es:

```text
https://mmembril.42.fr
```

Si el navegador se ejecuta en el host mientras Docker se ejecuta en una VM,
añade la IP de la VM al `/etc/hosts` del host, por ejemplo:

```text
172.16.47.132 mmembril.42.fr
```

Usa `127.0.0.1` solo cuando el navegador se ejecute dentro de la VM.

## 6. Comprobaciones de WordPress y PHP-FPM

El Dockerfile de WordPress debe instalar PHP-FPM y no debe instalar NGINX:

```sh
grep -nE 'FROM|php.*fpm|nginx' srcs/requirements/wordpress/Dockerfile
docker exec wordpress php-fpm8.2 -t
```

Comprueba que PHP-FPM escucha en el puerto de la red privada:

```sh
docker exec wordpress sh -c \
  "grep -E '^listen[[:space:]]*=' /etc/php/8.2/fpm/pool.d/www.conf"
```

Resultado esperado:

```text
listen = 0.0.0.0:9000
```

El sitio debe estar instalado; no debe mostrar la pantalla de instalación de WordPress:

```sh
docker exec wordpress wp core is-installed --allow-root
docker exec wordpress wp user list --allow-root
```

Debe haber dos usuarios. El nombre de usuario del administrador no debe incluir
`admin`/`Admin` ni `administrator`/`Administrator`.

Desde el navegador:

1. Abre `https://mmembril.42.fr`.
2. Inicia sesión en `https://mmembril.42.fr/wp-admin`.
3. Crea o edita una página.
4. Publícala.
5. Abre la página como visitante y verifica el cambio.
6. Añade un comentario con el usuario normal de WordPress y verifícalo.

## 7. Comprobaciones de MariaDB y de la base de datos

MariaDB debe tener su propio Dockerfile y no debe contener NGINX:

```sh
grep -nE 'FROM|nginx' srcs/requirements/mariadb/Dockerfile
```

Comprueba el volumen de la base de datos:

```sh
docker volume ls
docker volume inspect database
```

La inspección debe mostrar la ruta requerida del host:

```text
/home/mmembril/data/database
```

Conéctate usando las credenciales del `srcs/.env` local e ignorado:

```sh
set -a
. srcs/.env
set +a
docker exec -it mariadb \
  mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
```

Dentro del contenedor, las variables están disponibles mediante Compose. Un
ejemplo directo usando los valores de `.env` es:

```sh
docker exec -it mariadb \
  mariadb -uwordpress_user -ppassdb wordpress
```

No pongas credenciales reales en este documento ni en Git. La base de datos
debe contener tablas de WordPress:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT ID, user_login, user_email FROM wp_users;
```

El prefijo exacto de las tablas puede variar; inspecciona `wp-config.php` si es necesario.

## 8. Prueba de persistencia

Primero haz un cambio visible en WordPress y después reinicia la VM o al menos
los servicios Docker:

```sh
docker compose -f srcs/docker-compose.yml down
make
```

Después del inicio, verifica:

```sh
docker compose -f srcs/docker-compose.yml ps
docker volume inspect html
docker volume inspect database
```

La página editada, los usuarios, los comentarios y las tablas de la base de
datos deben seguir existiendo. Los directorios del host deben contener datos:

```sh
find /home/mmembril/data/html -maxdepth 2 -type f | head
find /home/mmembril/data/database -maxdepth 2 -type f | head
```

No uses `make clean` para esta prueba: elimina intencionadamente los datos
persistentes.

## 9. Lista de comprobación obligatoria

Antes de la defensa, confirma cada elemento:

- [ ] `Makefile` está en la raíz del repositorio.
- [ ] Todos los archivos de la aplicación están bajo `srcs/`.
- [ ] `srcs/.env` es local y está ignorado.
- [ ] No hay ninguna contraseña en un Dockerfile ni en un archivo versionado.
- [ ] Existe un Dockerfile personalizado para cada servicio.
- [ ] Cada Dockerfile parte de Debian o Alpine.
- [ ] Las imágenes se compilan localmente y usan etiquetas explícitas distintas de `latest`.
- [ ] Se ejecutan tres contenedores dedicados.
- [ ] Está presente la red `inception` definida por el usuario.
- [ ] No se usa la red `host`, `links` ni `--link`.
- [ ] No se usa ningún bucle infinito, `tail -f` ni `sleep infinity`.
- [ ] Solo NGINX publica el puerto 443.
- [ ] El puerto 80 no está expuesto.
- [ ] TLS está restringido a 1.2 y 1.3.
- [ ] WordPress usa PHP-FPM y no contiene NGINX.
- [ ] MariaDB no contiene NGINX.
- [ ] WordPress ya está instalado.
- [ ] Hay dos usuarios de WordPress.
- [ ] El nombre del administrador no contiene `admin` ni `administrator`.
- [ ] MariaDB tiene una base de datos de WordPress no vacía.
- [ ] Los dos volúmenes con nombre persisten bajo `/home/mmembril/data/`.
- [ ] Se pueden verificar una edición de página y un comentario.
- [ ] Los datos sobreviven a un reinicio.

La parte obligatoria está completa sin añadir servicios adicionales como FTP,
Redis, Adminer o Portainer.

## 10. Guion corto para la defensa

La evaluación no consiste solo en enseñar que los contenedores están encendidos.
El estudiante debe poder explicar y demostrar cada decisión importante:

1. `docker-compose.yml` define tres servicios independientes: `nginx`,
   `wordpress` y `mariadb`.
2. Cada servicio se construye con su propio Dockerfile desde Debian o Alpine.
3. `build:` usa los Dockerfiles locales. Las etiquetas de `image:` son explícitas
   y no usan `latest`; no deben confundirse con imágenes oficiales de aplicación.
4. NGINX es el único servicio publicado al host y termina TLS en el puerto 443.
5. WordPress habla con PHP-FPM por `wordpress:9000` y con MariaDB por
   `mariadb:3306`, usando el DNS interno de la red Docker.
6. MariaDB y WordPress permanecen en primer plano con un proceso real como PID 1;
   no se mantiene ningún contenedor vivo con `tail`, `sleep infinity` o un bucle.
7. Los datos sobreviven a `docker compose down` y a un reinicio, pero se eliminan
   intencionadamente con `make clean`.

Durante la defensa conviene mostrar primero la configuración y después el estado:

```sh
docker compose -f srcs/docker-compose.yml config
make
make ps
docker compose -f srcs/docker-compose.yml logs --tail=100
docker network inspect inception
docker volume inspect database
docker volume inspect html
```

## 11. Pruebas funcionales que deben hacerse

Con la pila arrancada, verifica también el comportamiento real:

```sh
curl -k -I https://mmembril.42.fr
curl -k -I https://mmembril.42.fr/wp-admin
docker exec nginx nginx -T 2>/dev/null | grep ssl_protocols
docker exec wordpress php-fpm8.2 -t
docker exec wordpress wp core is-installed --allow-root
docker exec wordpress wp user list --allow-root
docker exec mariadb mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
  -D "$MYSQL_DATABASE" -e 'SHOW TABLES;'
```

La prueba de persistencia debe hacerse sin `make clean`:

```sh
docker compose -f srcs/docker-compose.yml down
make
docker exec wordpress wp user list --allow-root
```

La página, los usuarios y la base de datos deben seguir disponibles después de
ese reinicio.

## 12. Comprobaciones previas a la entrega

Antes de entregar, confirma lo siguiente:

- El trabajo se ejecutará dentro de una máquina virtual.
- `DOMAIN_NAME` tiene el formato `<login>.42.fr` y coincide con el login real.
- `/home/<login>/data` coincide con el usuario de la evaluación, no con otro
  nombre de usuario.
- `srcs/.env` existe localmente, contiene valores reales y no está versionado.
- No hay contraseñas, certificados, claves privadas ni credenciales en Git.
- Se han probado credenciales diferentes para root de MariaDB, el usuario de la
  base de datos, el administrador de WordPress y el segundo usuario.
- El usuario administrador no contiene `admin` ni `administrator`, en ninguna
  combinación de mayúsculas y minúsculas.
- Hay exactamente dos usuarios de WordPress al terminar la instalación inicial.
- El puerto 80 no está publicado y MariaDB/PHP-FPM no están publicados al host.
- El certificado puede ser autofirmado, pero HTTPS funciona y solo permite TLS 1.2
  y TLS 1.3.
- Los directorios persistentes contienen datos después de la primera ejecución.
- `make`, `make down` y `make clean` tienen comportamientos entendidos antes de
  mostrarlos al evaluador.

Si Docker no está instalado o el proyecto no se ha probado en la VM, no se puede
afirmar que la entrega funcione aunque el análisis estático sea correcto. La
prueba mínima de aceptación es ejecutar `make` desde un estado limpio y comprobar
la web, los dos usuarios, la base de datos y la persistencia.

## 13. Preguntas habituales

### ¿Por qué hay una etiqueta en `image:`?

`image: nginx` equivale a `nginx:latest`, y el subject prohíbe `latest`. Por eso
se usan etiquetas explícitas como `nginx:1.0`, `wordpress:1.0` y `mariadb:1.0`.
Con `build:` Compose construye las imágenes locales; no se debe ejecutar un
`docker pull` de esas imágenes de aplicación.

### ¿Por qué se usan volúmenes con `driver_opts`?

El subject exige simultáneamente volúmenes Docker con nombre y almacenamiento en
`/home/<login>/data`. El controlador `local` con `driver_opts` permite conservar
el nombre Docker y apuntar sus datos a esa ruta. El evaluador puede pedir que se
muestre `docker volume inspect`; la ruta `Mountpoint` o las opciones del volumen
deben corresponder al usuario correcto.

### ¿Qué ocurre si el evaluador empieza sin `.env`?

`make prepare` puede crear `srcs/.env` desde el ejemplo, pero el ejemplo no debe
contener credenciales reales. Hay que editar `.env` y rellenar todos los valores
antes de arrancar la primera vez. No se deben enseñar ni entregar las
credenciales reales en Git.

### ¿Qué debe poder explicar el estudiante?

Debe poder describir `ENTRYPOINT`, `exec`, PID 1, la red puente, la resolución DNS
por nombre de servicio, los dos volúmenes, `depends_on`/healthcheck, el flujo
HTTPS -> NGINX -> PHP-FPM -> MariaDB y la diferencia entre `down` y `clean`.
