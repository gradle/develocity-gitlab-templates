# Develocity Docker images for GitLab CI

## Overview
GitLab templates require the modification of existing project templates in a fine-grained way, which is only sometimes possible.
As an alternative, we provide examples of Docker images when using [Docker](https://docs.gitlab.com/runner/executors/docker.html) or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) executor.

## Building the images
[build_docker_gradle.sh](build_docker_gradle.sh) and [build_docker_maven.sh](build_docker_maven.sh) are provided to build the images from the source files.
The images are based on "official" Gradle and Maven images from Dockerhub.
Script options are available to tweak the images, particularly for configuring the base image version.

For example:
```
./build_docker_gradle.sh --image myregistry/gradle-injection:1.0 --baseImageVersion 8.8.0-jdk11
./build_docker_maven.sh --image myregistry/maven-injection:1.0 --baseImageVersion 3.9.8-amazoncorretto-11 --mavenExtensionVersion 1.21.4
```

## Using the images
Assuming you have pushed the built image in a Docker registry, you can specify which image to use to run your jobs, either:
- In the [gitlab-ci.yaml template](https://docs.gitlab.com/runner/executors/docker.html#define-images-and-services-in-gitlab-ciyml) for specific jobs
- in the runner's [config.toml](https://docs.gitlab.com/runner/executors/docker.html#define-images-and-services-in-configtoml) for all jobs

## Configuration
Environment variables are available to configure the Develocity injection when the job runs.
Those environment variables can be set at any level, see [the docs](https://docs.gitlab.com/ee/ci/variables/).

The 2 most important ones are `DEVELOCITY_URL` and `DEVELOCITY_ACCESS_KEY` to control where build scans are published.

See the [Gradle Dockerfile](src/gradle/docker/Dockerfile) and [Maven Dockerfile](src/maven/docker/Dockerfile) for other available environment variables.
