## Gateway Docker

### About this Project
This repository contains **Dockerfile** of [Kaazing Gateway](http://kaazing.org/) for [Docker](https://www.docker.com/)'s automated build published to the public [Docker Hub Registry](https://hub.docker.com/_/kaazing-gateway/).

### Base Docker Image

* [dockerfile/ubuntu](http://dockerfile.github.io/#/ubuntu)


### Installation

1. Install [Docker](https://www.docker.com/).

2. Download build from public [Docker Hub Registry](https://registry.hub.docker.com/repos/kaazing/): `docker pull kaazing/gateway`

   (alternatively, you can build an image from Dockerfile: `docker build -t="kaazing/gateway" .`)

### Build locally
```bash
    docker build -t kaazing-gateway-dev .
```

### Usage

```bash
    docker run -h <hostname> -p 8000:8000 kaazing-gateway-dev
```

After few seconds, open `http://<hostname>:8000` to see the welcome page.  (Note: you may need to add hostname to etc/hosts from host machine, the ip address may be the boot2docker ip, or the ip of the docker host)

#### Attach persistent/shared directories to override the config

```bash
    docker run -p 8000:8000 -v <gateway-home-dir>:/kaazing-gateway kaazing-gateway-dev
```

#### Ambassador Pattern

The following illustrates the [ambassador pattern](https://docs.docker.com/engine/admin/ambassador_pattern_linking/) running between containers on two different hosts. It does not have trusted certs.

##### On docker host 1 (Server)

```bash
   ## Sets up backend
   docker run -d --name backend --hostname backend kaazing-gateway-dev ./bin/gateway.start --config conf/echo-config.xml


   ## Sets up ambassador
   docker run -d --name ambassador-server --link backend:backend -p 443:443 kaazing-gateway-dev start ambassador-server -service echo backend:8000
```

##### On docker host 2 (Client)

```bash
   ## Sets up ambassador 
   docker run -d --name ambassador-client kaazing-gateway-dev start ambassador-client ${ip-of-server-ambassador} -service echo 8000

   ## Runs up client
   docker run --rm -i -t --link ambassador-client:ambassador-client multicloud/netcat ambassador-client 8000
```

