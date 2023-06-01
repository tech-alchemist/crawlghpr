FROM ubuntu:22.04
RUN mkdir -p /root/.crawlghpr
RUN apt-get update
RUN apt-get -y install git curl jq vim python3 python3-pip python3-setuptools htop
WORKDIR /root/.crawlghpr
COPY . .
CMD bash crawlghpr_seamless.sh
