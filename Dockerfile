
FROM nginx:stable-alpine

RUN apk add bash
RUN apk add sed
RUN apk add acme-client

COPY default_server.conf /etc/nginx/conf.d/default_server.conf
COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /etc/ssl/acme
EXPOSE 80
STOPSIGNAL SIGTERM

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["www.example.com"]
