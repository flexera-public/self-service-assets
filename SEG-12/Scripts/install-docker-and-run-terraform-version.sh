#!/bin/bash -ex
# Installs Docker and run docker version

apt-get update -y
apt install docker docker.io -y
service docker start
docker pull hashicorp/terraform
docker run -i -t hashicorp/terraform:light version
mkdir /tmp/azure-aks/
cd /tmp/azure-aks/
echo "check_certificate = off" >> ~/.wgetrc
wget https://raw.githubusercontent.com/terraform-providers/terraform-provider-azurerm/master/examples/kubernetes/basic-cluster/main.tf
wget https://raw.githubusercontent.com/terraform-providers/terraform-provider-azurerm/master/examples/kubernetes/basic-cluster/outputs.tf
wget https://raw.githubusercontent.com/terraform-providers/terraform-provider-azurerm/master/examples/kubernetes/basic-cluster/variables.tf
