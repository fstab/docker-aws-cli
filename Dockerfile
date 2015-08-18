FROM ubuntu:14.04.3
MAINTAINER Fabian Stäber, fabian@fstab.de

#####################################################################################
# Current version is aws-cli/1.7.45 Python/2.7.6
#####################################################################################

RUN apt-get update && \
    apt-get upgrade -y

RUN apt-get install -y \
    ssh \
    python \
    python-pip \
    python-virtualenv

RUN adduser --disabled-login --gecos '' aws
WORKDIR /home/aws

USER aws

RUN \
    mkdir aws && \
    virtualenv aws/env && \
    ./aws/env/bin/pip install awscli && \
    echo 'source $HOME/aws/env/bin/activate' >> .bashrc && \
    echo 'complete -C aws_completer aws' >> .bashrc

USER root

RUN mkdir examples
ADD examples/start.sh /home/aws/examples/start.sh
ADD examples/terminate.sh /home/aws/examples/terminate.sh
ADD examples/init-instance.script /home/aws/examples/init-instance.script
ADD examples/README.md /home/aws/examples/README.md
RUN chown -R aws:aws /home/aws/examples

USER aws
