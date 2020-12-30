#!/bin/bash -e

mkdir -p  /tmp/.terraform
cat <<EOS> /tmp/tf/.env.list
ARM_ACCESS_KEY=$ARM_ACCESS_KEY
ARM_TENANT_ID=$ARM_TENANT_ID
ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET
ARM_CLIENT_ID=$ARM_CLIENT_ID
TF_VAR_location=$TF_VAR_location
TF_VAR_prefix=$TF_VAR_prefix
EOS

cat <<EOF> /tmp/tf/backend.conf
resource_group_name="AADDS"
storage_account_name="tfstateflexera"
container_name="tfstate"
key="${TF_VAR_prefix}.terraform.tfstate"
EOF

docker run --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
--env-file /tmp/tf/.env.list \
hashicorp/terraform:light init -backend=true -backend-config=/tf/backend.conf /tf/ 2>&1

docker run --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
--env-file /tmp/tf/.env.list \
hashicorp/terraform:light plan /tf/ 2>&1

docker run --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
--env-file /tmp/tf/.env.list \
hashicorp/terraform:light apply -auto-approve /tf/ 2>&1
