FROM debian:12.11
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl php8.2-fpm php8.2-mysqli php8.2-curl php8.2-gd php8.2-mbstring php8.2-xml php8.2-zip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://wordpress.org/wordpress-6.6.2.tar.gz | tar -xz -C /usr/src \
    && curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/wordpress-entrypoint
RUN chmod +x /usr/local/bin/wordpress-entrypoint && mkdir -p /run/php /var/www/html
EXPOSE 9000
ENTRYPOINT ["wordpress-entrypoint"]
