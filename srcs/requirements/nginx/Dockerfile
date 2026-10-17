FROM debian:12.11

RUN apt-get update && apt-get install -y --no-install-recommends nginx openssl \
    && rm -f /var/www/html/index.nginx-debian.html \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 443

COPY ./conf/default /etc/nginx/sites-enabled/default
COPY ./tools/nginx_start.sh /var/www

RUN chmod +x /var/www/nginx_start.sh

ENTRYPOINT [ "/var/www/nginx_start.sh" ]

CMD [ "nginx", "-g", "daemon off;" ]
