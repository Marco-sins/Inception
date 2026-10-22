FROM debian:12.11
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx openssl && rm -rf /var/lib/apt/lists/*
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/nginx-entrypoint
RUN chmod +x /usr/local/bin/nginx-entrypoint
EXPOSE 443
ENTRYPOINT ["nginx-entrypoint"]
