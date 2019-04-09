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

ENV BASHRC_FILE=/root/.bashrc
RUN echo "" >> $BASHRC_FILE \
 && echo "export LD_LIBRARY_PATH=/usr/local/lib/:/usr/local/lib/JAGS/modules-5/" >> $BASHRC_FILE \
 && echo "" >> $BASHRC_FILE

RUN export LD_LIBRARY_PATH=/usr/local/lib/:/usr/local/lib/JAGS/modules-5/ \
 && git clone https://github.com/rohan-shah/magicCalling.git \
 && cd magicCalling \
 && R CMD INSTALL . \
 && rm -rf /magicCalling

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini \
 && echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - \
 && mv tini /usr/local/bin/tini \
 && chmod +x /usr/local/bin/tini

# Configure container startup
ENTRYPOINT ["tini", "--"]

# Overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
