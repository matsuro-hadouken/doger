FROM bitnami/minideb:stretch

LABEL maintainer="Matsuro Hadouken <matsuro-hadouken@protonmail.com>"
LABEL version="5.1.1.6"
LABEL name="DogeCash MainNet"

SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

WORKDIR /usr/local/bin/

ARG DEBIAN_FRONTEND=noninteractive

COPY tools_and_fools /usr/local/bin/

RUN apt-get clean && apt-get update -y && apt-get install -y apt-utils 2>&1 | grep -v "debconf: delaying package configuration, since apt-utils is not installed" && apt-get install -y --no-install-recommends nano && apt-get install -y --no-install-recommends unzip && apt-get install -y --no-install-recommends unzip && apt-get install -y --no-install-recommends net-tools  && apt-get install -y --no-install-recommends wget && apt-get install -y --no-install-recommends curl \
  && adduser dogecash --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password > /dev/null && usermod -a -G dogecash dogecash \
  && mkdir -p /home/dogecash/.dogecash && mv /usr/local/bin/dogecash.conf /home/dogecash/.dogecash/ && mv /usr/local/bin/header.txt /home/dogecash/ \
  && chmod a+x /usr/local/bin/* && chown -R dogecash:dogecash /home/dogecash/.dogecash && chown -R dogecash:dogecash /usr/local/bin/*

USER dogecash

VOLUME [ "/home/dogecash/.dogecash" ]

EXPOSE 41001