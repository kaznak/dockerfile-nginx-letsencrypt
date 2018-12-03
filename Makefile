
DEFAULT_HOST=www.example.com

image: .make.image

.make.image: Dockerfile default_server.conf docker-entrypoint.sh
	docker build -t kaznak/nginx-letsencrypt .
	touch .make.image

test/nginx.conf.d/${HOST}.conf: test/nginx.conf.d/${DEFAULT_HOST}.conf
	sed -e "s/${DEFAULT_HOST}/${HOST}/g" test/nginx.conf.d/${DEFAULT_HOST}.conf	> test/nginx.conf.d/${HOST}.conf

test: .make.image test/nginx.conf.d/${HOST}.conf
	sudo rm -rf test/acmeroot/${HOST} test/acmeroot/private/${HOST}
	mkdir -p test/acmeroot/private	|| true
	docker run -e HOSTS="${HOST}"	\
		-p 80:80	\
		-v ${PWD}/test/acmeroot:/etc/ssl/acme	\
		kaznak/nginx-letsencrypt
	name=$(docker run -d -e HOSTS="${HOST}"	\
		-p 80:80 -p 443:443	\
		-v ${PWD}/test/nginx.conf.d/${HOST}.conf:/etc/nginx/conf.d/${HOST}.conf	\
		-v ${PWD}/test/acmeroot:/etc/ssl/acme	\
		-v ${PWD}/test/webroot:/var/www/html		\
		kaznak/nginx-letsencrypt)
	curl -v "https://${HOST}/"
	docker container stop ${name}
	docker container rm ${name}

all: .make.image
