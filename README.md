# IcecreamTruck

IcecreamTruck is a ruby on rails based json web app for managing purchases and inventory on an icecream truck.

## Prerequisites

This application has been developed in Linux under a ruby environment managed by `rvm`.  It is highly recommended that you use `rvm` or `rbenv` to manage the ruby environment for this application.  If you have `rvm` installed it will guide you through setting up your environment when you change into the source directory on the command line.

It should run under OSX and windows with WSL but I do not have the environments to test this.  If you have a problem please create a ticket in github.

It is assumed you have a recent version of `docker` and `docker-compose` setup and running on your system.

The application also requires a postgresql database which we will run in docker.

## Installation

Clone the code from github, change into the directory and run bundle install using the commands given bellow.

```console
git clone https://github.com/emiddleton/icecreamtruck.git
cd icecreamtruck
bundle install
```

## Database setup

For local development and running tests you will need to setup a dockerized postgresql server using the following commands.

```console
docker run -e POSTGRES_USER=developer \
           -e POSTGRES_PASSWORD=development-password \
           -p 0.0.0.0:5432:5432 \
           -d postgres \
           postgres -N 1000
```

When this completes you will need to create the initial database with

```console
rails db:create db:migrate
```

### What to do if you have an existing postgresql server running
  
If you have an existing postgresql server running on your machine the port it is using will conflict with the one the docker instance is exposed on.  You will need to either stop the existing server before running the above command or change the port number the dockerized postgresql is exposed on.  The process for running docker on a different port is explained bellow.  Start by running the dockerized postgresql with the below command which will expose it on the first available port

```console
docker run -e POSTGRES_USER=developer \
           -e POSTGRES_PASSWORD=development-password \
           -p 0.0.0.0:0:5432 \
           -d postgres \
           postgres -N 1000
```

To find which port was, used run the `docker ps` command.  In the example below postgresql is being exposed on port 49153

```console
$ docker ps
CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS                     NAMES
702e80ab39a6   postgres   "docker-entrypoint.s…"   4 seconds ago    Up 2 seconds    0.0.0.0:49153->5432/tcp   suspicious_wilbur
```

You will now need to update the database port number in the `config/database.yml` file to point to the port your database is exposed on, as shown in this example bellow (in the examples the port is 49143).

```yaml
..
development_default: &development_default
  <<: *default
  host: 127.0.0.1
  port: 49153
...
```

When this completes you will need to create the initial database with

```console
rails db:create db:migrate
```

## Running Tests

Tests are implemented in `rspec`.  To run all test type `rspec` in the source root directory.  Code coverage report will be generated in coverage/index.html when the test complete.

## Testing the Production Like Environment

You can run the application locally using docker-compose with the following command which will start the application in a production like environment, using its own database and exposing an API on localhost port 80

```console
docker-compose run web-api rails db:create db:migrate && \
  docker-compose up
```

you can use control-c to stop the running containers

## Upgrading the Production Like Environment

To upgrade just the rails containers

1. use control-c to stop the running containers

2. run the following.

```console
docker-compose rm --force web-api && \
  docker-compose up --no-start --no-recreate --build web-api && \
  docker-compose up
```

## Removing the Production Like Environment

**WARN: this will loose all data in the containers database**

1. Use control-c to stop running containers

2. remove all running and stopped containers (WARN: this will destroy all data in database)

```console
docker-compose kill && \
  docker-compose rm
```
