## Gateway Docker

### About this Project
This repository contains **Dockerfile** of [Kaazing Gateway](http://kaazing.org/) for [Docker](https://www.docker.com/)'s automated build published to the public [Docker Hub Registry](https://registry.hub.docker.com/repos/kaazing/).

### Base Docker Image

* [dockerfile/ubuntu](http://dockerfile.github.io/#/ubuntu)


### Installation

1. Install [Docker](https://www.docker.com/).

2. Download build from public [Docker Hub Registry](https://registry.hub.docker.com/repos/kaazing/): `docker pull kaazing/gateway`

   (alternatively, you can build an image from Dockerfile: `docker build -t="kaazing/gateway" .`)

### Usage

    docker run -h <hostname> -p 8000:8000 kaazing/gateway

#### Attach persistent/shared directories

    docker run -p 8000:8000 -v <gateway-home-dir>:/kaazing-gateway kaazing/gateway

After few seconds, open `http://<hostname>:8000` to see the welcome page.  (Note: you may need to add hostname to etc/hosts from host machine, the ip address may be the boot2docker ip, or the ip of the docker host)

