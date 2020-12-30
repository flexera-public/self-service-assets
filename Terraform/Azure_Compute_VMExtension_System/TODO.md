# TODO

## CAT Changes

1. Link To StateFile in Output
2. Clean up vm
3. cd /tmp/tf/@@execution.id
4. param_execution_id_override.

## Script Changes

1. install-docker-and-run-terraform-version.sh - create execution directory based of @@execution.id.
2. docker-run-terraform-plan.sh - Create azure backend via CAT<<EOF
3. download-tf-files.sh - cd /tmp/tf/@@execution.id
4. docker-run-terraform-plan.sh - terraform init --backend-config=

## Terraform Plan Changes

1. Add variable for execution id.
2. Add execution Id tag

## Notes from PR

```text
Link to State ile
Create azure backend as a separate.
Keep the path to the files.
Execution ID and Files.
Delete VM After
Delete with orphaned executions in State file
Execution ID Override.
Tag Execution ID
Policies - find by execution id.
```
