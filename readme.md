# CI/CD Pipeline using Docker and Coolify

This guide outlines how to set up a CI/CD pipeline to build and deploy a Docker image using Coolify.
The process involves creating a Docker image, pushing it to Docker Hub, and using Coolify to manage 
deployment through Docker Compose when a new release is published.

## Create the Dockerfile

Start by creating the Dockerfile that will define how your application is built and packaged into a
Docker image. Below is an example Dockerfile for a Go application:

```docker
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

Finally, set up your project on Coolify. Follow Coolify’s interface to connect the repository. 
Once done, Coolify will now be able to deploy the application.

## Build, push image and deploy with Github Actions

To automate the build and push process, you can use GitHub Actions.

 1. Create a Docker Hub Access Token: Go to Docker Hub and generate a personal access token.
 2. Add the Token as a GitHub repository secret and name it `DOCKER_HUB_TOKEN`.
 3. Create a Coolify API key: Go to Keys & Tokens > API Tokens.
 4. Add the API key as a GitHub repository secret and name it `COOLIFY_TOKEN`.
 5. Get the webhook endpoint from Coolify: Your resource > Webhook menu > Deploy Webhook and add it as a GitHub repository secret as `COOLIFY_WEBHOOK`. 
 6. Create the GitHub Actions Workflow: Add a new yaml file under .github/workflows with the following content:

```yml
name: Docker image CI

on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build Docker image
      run: docker build --platform linux/amd64 -t anvigy/api-example .
    - name: Push Docker image
      run: |
        docker login -u anvigy -p ${{ secrets.DOCKER_HUB_TOKEN }}
        docker push anvigy/api-example:latest
    - name: Deploy to Coolify
      run: |
        curl --request GET '${{ secrets.COOLIFY_WEBHOOK }}' --header 'Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}'
```

This will automatically build, push your Docker image and trigger your Coolify resource to make a new deployment
whenever a new release is published.
