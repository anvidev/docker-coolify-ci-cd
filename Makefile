docker-build:
	@docker build -t anvigy/api-example .

docker-build-linux:
	@docker build --platform linux/amd64 -t anvigy/api-example .

docker-run:
	@docker run -p 8080:8080 anvigy/api-example 

docker-push:
	@docker push anvigy/api-example:latest
