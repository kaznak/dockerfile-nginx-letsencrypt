
# docekrfile nginx letsencrypt

Dockerfile : nginx + letsencrypt

## Usage

replace www.example.com to actual hostname.

### Fetch let's encrypt Certification

~~~
docker run -p 80:80 -v $PWD/acme-client:/etc/ssl/acme kaznak/nginx-letsencrypt new www.example.com
~~~

### Run server

~~~
docker run -p 80:80 -v $PWD/acme-client:/etc/ssl/acme -v $PWD/nginx.conf.d/www.example.com:/etc/nginx/conf.d/www.example.com kaznak/nginx-letsencrypt run www.example.com
~~~

## Reference
+ [Nginx as reverse proxy with acme (letsencrypt)]( https://wiki.alpinelinux.org/wiki/Nginx_as_reverse_proxy_with_acme_(letsencrypt) )
+ [Official Repository : nginx @dockerhub](https://hub.docker.com/_/nginx/)

