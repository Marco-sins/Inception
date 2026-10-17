*This project has been created as part of the 42 curriculum by mmembril.*

# Inception

## Description

Inception deploys a small Docker infrastructure composed of three containers:

- NGINX with TLS 1.2/1.3.
- WordPress with PHP-FPM.
- MariaDB for the WordPress database.

The services communicate through a private Docker network. NGINX is the only
service accessible from outside and uses port `443`.

## Instructions

See [USER_DOC.md](./USER_DOC.md) for installation and usage instructions.
Technical details and mandatory checks are available in
[DEV_DOC.md](./DEV_DOC.md).

## Resources

- [Docker documentation](https://docs.docker.com/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [WordPress documentation](https://wordpress.org/documentation/)

AI was used to help review the repository, compare it with the mandatory
subject requirements, and organize this documentation. The final configuration
must be understood and verified by the project author.
