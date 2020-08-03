name "Google Cloud Storage KV"
rs_ca_ver 20161221
short_description "Google Cloud Storage KV"
package "google/kv_utils"
import "sys_log"
import "google/cloud_storage"

# This function initializes the global variable $$workflow_kv_store for later uses
# Usage: 
# call kv_utils.initialize("secret_bucket",["base.json"])
# call kv_utils.initialize("secret_bucket",["base.json","production.json"])

define initialize($bucket,$objects) do
  $$workflow_kv_store = {}
  foreach $object in $objects do
    $credential_file = google.cloud_storage.get(bucket: $bucket, object: $object)
    $hash_credential_file = from_json($credential_file)
    foreach $key in $hash_credential_file do
      $$workflow_kv_store[$key] = $hash_credential_file[$key]
    end
  end
end

# This function merges an additional file into the $$workflow_kv_store variable,
# it will overwrite existing keys. Its preferrable to initialize all in the beginning.
# Usage: 
# call kv_utils.merge("secret_bucket","base.json")
define merge($bucket, $object) do
  $additional_file = google.cloud_storage.get(bucket: $bucket, object: $object)
  $hash_additional_file = from_json($additional_file)
  foreach $key in $hash_additional_file do
    $$workflow_kv_store[$key] = $hash_additional_file[$key]
  end
end

# This function is used to retrieve a value from the key value global variable $$workflow_kv_store
# Usage: 
# call kv_utils.get("username") retrieve $username
define get($key) return $value do
  $value = $$workflow_kv_store[$key]
end