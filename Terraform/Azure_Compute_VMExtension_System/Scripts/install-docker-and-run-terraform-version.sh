#!/bin/bash -ex
# Installs Docker and run docker version
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install docker docker.io -y
service docker start
docker pull hashicorp/terraform
docker run -i -t hashicorp/terraform:light version
mkdir /tmp/azure-aks/
cd /tmp/azure-aks/
