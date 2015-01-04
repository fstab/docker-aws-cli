FROM ubuntu:14.04
MAINTAINER Fabian Stäber, fabian@fstab.de

RUN apt-get update && \
    apt-get upgrade -y

RUN apt-get install -y \
    python \
    python-pip \
    python-virtualenv

RUN adduser --disabled-login --gecos '' aws
USER aws
WORKDIR /home/aws

RUN \
    mkdir aws && \
    virtualenv aws/env && \
    ./aws/env/bin/pip install awscli && \
    echo 'source $HOME/aws/env/bin/activate' >> .bashrc && \
    echo 'complete -C aws_completer aws' >> .bashrc
