#!/bin/bash -ex
docker run -i -t --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
-e ARM_ACCESS_KEY="$ARM_ACCESS_KEY" \
-e ARM_TENANT_ID="$ARM_TENANT_ID" \
-e ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID" \
-e ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET" \
-e ARM_CLIENT_ID="$ARM_CLIENT_ID" \
hashicorp/terraform:light init /tf/

docker run -i -t --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
-e ARM_ACCESS_KEY="$ARM_ACCESS_KEY" \
-e ARM_TENANT_ID="$ARM_TENANT_ID" \
-e ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID" \
-e ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET" \
-e ARM_CLIENT_ID="$ARM_CLIENT_ID" \
hashicorp/terraform:light plan /tf/

docker run -i -t --mount type=bind,source=/tmp/tf,target=/tf \
--mount type=bind,source=/tmp/.terraform,target=/.terraform \
-e ARM_ACCESS_KEY="$ARM_ACCESS_KEY" \
-e ARM_TENANT_ID="$ARM_TENANT_ID" \
-e ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID" \
-e ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET" \
-e ARM_CLIENT_ID="$ARM_CLIENT_ID" \
hashicorp/terraform:light apply /tf/