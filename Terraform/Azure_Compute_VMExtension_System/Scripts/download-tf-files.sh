#!/bin/bash -ex

mkdir -p /tmp/tf
cd /tmp/tf
wget https://s3.amazonaws.com/rightscale-services/terraform/TF/main.tf
wget https://s3.amazonaws.com/rightscale-services/terraform/TF/outputs.tf
wget https://s3.amazonaws.com/rightscale-services/terraform/TF/variables.tf