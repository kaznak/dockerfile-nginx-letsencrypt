
image: Dockerfile default_server.conf docker-entrypoint.sh docker-entrypoint.new.sh docker-entrypoint.run.sh
	docker build -t kaznak/nginx-letsencrypt .

all: image
