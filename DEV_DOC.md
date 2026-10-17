# Developer Documentation

## Entorno de desarrollo / corrección
- SO objetivo: Debian 12 (la evaluación se realiza sobre una VM Debian).  
- Usuario esperado: `mmembril`. Las rutas de volúmenes usan `/home/mmembril/data/...` por diseño.
- Requisitos: `docker`, `docker-compose`, `make`.

## Estructura relevante
- `inception/srcs/docker-compose.yml` — definición de servicios, redes y volúmenes.  
- `inception/srcs/requirements/` — Dockerfiles y configuraciones por servicio.  
- `inception/srcs/env.txt` — plantilla para generar `inception/srcs/.env` (no versionado).

## Variables de entorno (`.env`)
La plantilla se encuentra en `inception/srcs/env.txt`. Copia y edita antes de levantar el stack:

```bash
cp inception/srcs/env.txt inception/srcs/.env
nano inception/srcs/.env
```

Variables principales (explicación):
- `MYSQL_DATABASE`, `MYSQL_ROOT_USER`, `MYSQL_ROOT_PASSWORD`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_HOSTNAME`: configuración de MariaDB.  
- `DOMAIN_NAME`: dominio usado por WordPress / NGINX.  
- `WORDPRESS_ADMIN`, `WORDPRESS_ADMIN_PASS`, `WORDPRESS_ADMIN_EMAIL`: credenciales admin WP.  
- `WORDPRESS_USER`, `WORDPRESS_USER_PASS`, `WORDPRESS_EMAIL`: usuario adicional.

Nota: no subas `inception/srcs/.env` al repositorio; mantenerlo fuera es la práctica recomendada. Si se desea mayor seguridad en producción, migrar a Docker secrets.

## Build y ejecución
1. Desde la raíz del repo:  
```bash
make
```
2. Para detener:  
```bash
make down
```
3. Para limpiar datos locales (ADVERTENCIA: borrará datos):  
```bash
make clean
```

## Volúmenes y persistencia
Los volúmenes están ligados a rutas host bind:  
- MariaDB: `/home/mmembril/data/mysql`  
- WordPress: `/home/mmembril/data/wordpress`

Para verificar desde la VM del corrector:  
```bash
docker volume ls
docker volume inspect <volume_name>
```
El `device` debe contener `/home/mmembril/data/`.

## Recompilar tras cambio de configuración
Si modificas un Dockerfile o un archivo de configuración (por ejemplo `conf/`), reconstruye y reinicia:

```bash
make down
make
```

## Puntos a justificar en la defensa
- Motivo de no versionar `.env` (seguridad).  
- Elección de `debian:12.11` como imagen base (compatibilidad con paquetes, versión estable).  
- Estructura del repo y por qué `srcs` está en `inception/srcs` (documentarlo si el corrector exige `srcs/` en la raíz).
