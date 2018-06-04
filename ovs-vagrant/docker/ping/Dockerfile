FROM nginx:stable

MAINTAINER Davide Polonio <poloniodavide@gmail.com>

RUN apt-get update && \
    apt-get install -y iputils-ping curl tcpdump && \
    rm -rf /var/lib/apt/lists/*

RUN cd /usr/share/nginx/html && \
    curl http://ubuntu.mirrors.ovh.net/ubuntu-releases/18.04/ubuntu-18.04-live-server-amd64.iso --output ubuntu.iso
