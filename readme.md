# CI/CD Pipeline using Docker and Coolify

This guide outlines how to set up a CI/CD pipeline to build and deploy a Docker image using Coolify.
The process involves creating a Docker image, pushing it to Docker Hub, and using Coolify to manage 
deployment through Docker Compose when new commits or pull requests are merged into the `main` branch.

## Create the Dockerfile

Start by creating the Dockerfile that will define how your application is built and packaged into a
Docker image. Below is an example Dockerfile for a Go application:

```yml
FROM golang:1.23 AS builder
WORKDIR /app 
COPY go.* .
RUN go mod download && go mod verify
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o api ./cmd/api

FROM scratch
WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/api .
EXPOSE 8080
CMD ["./api"]
```

## Build the docker image

Once your Dockerfile is created, you can build the image locally. The following command uses the Docker
CLI to build the image. It's important to tag the image with a version for easier rollbacks in production.
By default, Docker applies the latest tag.

```bash
# without tag
docker build --platform linux/amd64 -t anvigy/api-example .

# with tag
docker build --platform linux/amd64 -t anvigy/api-example:1.0.4 .
```

To verify that the image was successfully built, you can list all images on your local machine:

```bash
docker image list
```

You can also test the image locally by running it with Docker:

```bash
docker run -p 8080:8080 anvigy/api-example
```

## Create a docker-compose file

To deploy the application on your server, you'll need a Docker Compose file. This file will define the
services and settings for running the containerized application. Here’s an example:

```yml
services:
    api:
        image: anvigy/api-example
        ports:
            - "8080:8080"

```

## Create a new repository at Docker Hub

Next, sign in to Docker Hub or create a new account if you don't already have one. Navigate to the
"Repositories" section and create a new repository. The name of the repository will be used in the 
Docker Compose file to reference the image.

For example, you might name your repository `api-example`.

## Push image to Docker Hub

After building the Docker image, you can push it to your Docker Hub repository using the following command:

```bash
docker push anvigy/api-example:latest
```

This command uploads the image so that your VPS can pull it when deploying with Docker Compose.

## Add new project to Coolify

Finally, set up your project on Coolify. Follow Coolify’s interface to connect the repository and 
configure the pipeline. Once done, Coolify will automatically deploy your application when there are 
new commits or pull requests merged into the main branch.
