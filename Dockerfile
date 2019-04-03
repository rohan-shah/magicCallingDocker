# Copyright (c) Jupyter Development Team.
# Copyright (c) CMRI-ProCan Team.
# Distributed under the terms of the Modified BSD License.

FROM ubuntu:18.04

USER root
ENV DEBIAN_FRONTEND noninteractive
COPY packages.txt .
RUN apt-get update \
 && apt-get -yq dist-upgrade \
 && cat packages.txt | xargs apt-get install -y --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.ssh/ \
 && ssh-keyscan -H hg.code.sf.net >> ~/.ssh/known_hosts \
 && git clone https://github.com/rohan-shah/mcmc-jags.git jags \ 
 && cd jags \ 
 && mkdir build \
 && cd build \
 && cmake -DCMAKE_BUILD_TYPE=Release .. \ 
 && touch tmp

RUN cd /jags/build \
 &&  make && make install

COPY Rpackages.txt .
RUN R -e "packages <- read.table('./Rpackages.txt', stringsAsFactors=FALSE); install.packages(packages[,1]);"
RUN git clone https://github.com/rohan-shah/rjags.git \
 && cd rjags \ 
 && mkdir build \
 && cd build \ 
 && cmake -DCMAKE_BUILD_TYPE=Release -Djags_DIR=/jags/build -Dbugs_DIR=/jags/build -Dbase_DIR=/jags/build .. \
 && make && make install

RUN rm -rf /jags \
 && rm -rf /rjags \
 && rm /Rpackages.txt \
 && rm /packages.txt 
