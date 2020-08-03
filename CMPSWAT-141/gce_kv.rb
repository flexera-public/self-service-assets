name "Google Cloud Storage KV"
rs_ca_ver 20161221
short_description "Google Cloud Storage KV"
package "google/kv_utils"
import "sys_log"
import "google/cloud_storage"

define initialize($bucket,$object) do
  $$workflow_kv_store = {}
  $credential_file = google.cloud_storage.get(bucket: $bucket, object: $object )
  $$workflow_kv_store = from_json($credential_file)
end

define get($key) return $value do
  $value = $$workflow_kv_store[$key]
end