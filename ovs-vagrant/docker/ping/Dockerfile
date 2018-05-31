FROM nginx:stable

MAINTAINER Davide Polonio <poloniodavide@gmail.com>

RUN apt-get update && \
    apt-get install -y iputils-ping && \
    rm -rf /var/lib/apt/lists/*
