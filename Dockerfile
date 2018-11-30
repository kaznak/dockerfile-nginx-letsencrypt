
FROM nginx:stable-alpine

RUN apk add bash
RUN apk add sed
RUN apk add acme-client

VOLUME /data

COPY /data/default_server.conf /etc/nginx/conf.d/default_server.conf
COPY /data/docker-entrypoint.sh /usr/local/bin/

EXPOSE 80 443

STOPSIGNAL SIGTERM

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
