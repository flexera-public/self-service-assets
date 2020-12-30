#!/bin/bash -e
env
mkdir -p  /tmp/.terraform
docker run --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
-e ARM_ACCESS_KEY="$ARM_ACCESS_KEY" \
-e ARM_TENANT_ID="$ARM_TENANT_ID" \
-e ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID" \
-e ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET" \
-e ARM_CLIENT_ID="$ARM_CLIENT_ID" \
-e TF_VAR_location="$TF_VAR_location" \
-e TF_VAR_prefix="$TF_VAR_prefix" \
hashicorp/terraform:light init /tf/

docker run --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
-e ARM_ACCESS_KEY="$ARM_ACCESS_KEY" \
-e ARM_TENANT_ID="$ARM_TENANT_ID" \
-e ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID" \
-e ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET" \
-e ARM_CLIENT_ID="$ARM_CLIENT_ID" \
-e TF_VAR_location="$TF_VAR_location" \
-e TF_VAR_prefix="$TF_VAR_prefix" \
hashicorp/terraform:light destroy -auto-approve /tf/ 1>&2
