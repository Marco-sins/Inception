# Inception - documentación técnica

## Arquitectura obligatoria

El proyecto debe ejecutarse en una máquina virtual usando Docker Compose:

```text
NGINX :443 (TLS) -> WordPress/PHP-FPM -> MariaDB
```

Debe haber tres contenedores independientes, una red Docker propia y dos
volúmenes nombrados: uno para `/var/lib/mysql` y otro para
`/var/www/html`. Los datos deben persistir en `/home/mmembril/data`.

Cada imagen debe construirse con su propio Dockerfile basado en Debian o
Alpine. No se permiten imágenes preparadas de WordPress, NGINX o MariaDB.

## Requisitos de validación

- Solo NGINX publica el puerto `443`.
- NGINX usa únicamente TLS 1.2 y/o 1.3.
- WordPress contiene PHP-FPM, pero no NGINX.
- MariaDB no contiene NGINX.
- Los servicios usan la red declarada en Compose; no `host`, `links` ni
  `--link`.
- Los contenedores tienen `restart: always`.
- WordPress crea dos usuarios y el administrador no contiene `admin`.
- Las contraseñas llegan mediante variables de entorno.
- No se utiliza la etiqueta `latest`.
- No se usan bucles infinitos como `tail -f` o `sleep infinity`.

Validar antes de arrancar:

```bash
docker compose -f srcs/docker-compose.yml config
```

## Implementación

MariaDB incluye un `healthcheck` y WordPress espera a que esté saludable antes
de iniciar. Los scripts tienen errores explícitos y esperas limitadas. El
Makefile solo gestiona los recursos de este proyecto; `clean` elimina también
los datos persistentes.

Las credenciales reales deben crearse en `srcs/.env`, que está excluido de Git.
El fichero `srcs/env.txt` solo contiene valores de ejemplo.

Esta documentación cubre únicamente la parte obligatoria; el bonus queda
fuera del alcance.
