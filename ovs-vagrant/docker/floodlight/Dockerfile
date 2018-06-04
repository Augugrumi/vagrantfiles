FROM anapsix/alpine-java:8_jdk

MAINTAINER Davide Polonio <poloniodavide@gmail.com>

RUN mkdir /floodlight
VOLUME /floodlight

RUN apk add --no-cache gcc g++ make libc-dev apache-ant python-dev git && \
    apk add maven --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community/ && \
    rm -rf /var/cache/apk/*

RUN set -e && echo -e "#!/bin/bash \\n \
set -e; \
cd /floodlight; \
ant clean; \
ant; \
mkdir -p /var/lib/floodlight; \
chmod 777 /var/lib/floodlight; \
cd -" | tee /usr/bin/flc &> /dev/null; \
    echo -e "#!/bin/bash \\n \
set -e; \
cd /floodlight; \
java -jar target/floodlight.jar; \
cd -" | tee /usr/bin/fle &> /dev/null; \
    chmod +x /usr/bin/flc && \
    chmod +x /usr/bin/fle

WORKDIR /floodlight

EXPOSE 8080 6653

CMD /usr/bin/bash
