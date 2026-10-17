*This project has been created as part of the 42 curriculum by mmembril.*

# Inception

## Description
Inception is a system administration project that deploys a small Docker infrastructure. The goal is to virtualize several Docker images, set up a secure web server (NGINX), a database (MariaDB), and a dynamic website (WordPress), communicating via a dedicated internal Docker network.

## Instructions
1. Ensure your local domain is mapped in `/etc/hosts`: `127.0.0.1 mmembril.42.fr`
2. Build and run the complete project: `make`
3. Stop the containers: `make down`
4. Remove the complete environment (containers, volumes, images): `make clean`
*Note: Make sure your user is in the `docker` group, or use `sudo`.*

## Project Description
This project uses Docker to containerize services instead of running them directly on the host, ensuring reproducibility, high performance, and environmental isolation.

- **Virtual Machines vs Docker:** VMs virtualize entire Operating Systems including hardware, making them heavy. Docker virtualizes at the OS level, sharing the host's kernel, making them much faster and lighter.
- **Secrets vs Environment Variables:** Environment variables are key-value pairs great for passing dynamic configuration. Secrets are encrypted and far safer for passing sensitive data like passwords.
- **Docker Network vs Host Network:** A Docker Network isolates containers so only explicitly linked ones can interact. Host Network drops this isolation, directly exposing container services to the host's interface.
- **Docker Volumes vs Bind Mounts:** Volumes are fully managed by Docker, safer, and persistent across container restarts. Bind mounts map an exact host directory onto the container, which depends heavily on the host OS file structure.

## Resources
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress Support](https://wordpress.org/support/)