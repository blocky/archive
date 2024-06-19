FROM amazonlinux:2

SHELL ["/bin/bash", "-c"]

RUN amazon-linux-extras install aws-nitro-enclaves-cli -y
RUN yum install aws-nitro-enclaves-cli-devel -y
