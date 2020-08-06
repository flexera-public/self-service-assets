name "Google Cloud Storage KV"
rs_ca_ver 20161221
short_description "Google Cloud Storage KV"
package "google/kv_utils"
import "sys_log"
import "plugins/google_cloud_storage"

parameter "google_project" do
  like $google_cloud_storage.google_project
  operations "launch"
end

# This function initializes the global variable $$workflow_kv_store for later uses
# Usage: 
# call kv_utils.initialize("secret_bucket",["base.json"])
# call kv_utils.initialize("secret_bucket",["base.json","production.json"])

define initialize($bucket,$objects) do
  $$workflow_kv_store = {}
  foreach $object in $objects do
    call start_debugging()
    sub on_error: stop_debugging() do
      @credential_file = google_cloud_storage.objects.show(bucket_name: $bucket, object_name: $object)
      $response = @credential_file.content()
      $hash_credential_file = $response[0]
      call stop_debugging()
      foreach $key in keys($hash_credential_file) do
        $$workflow_kv_store[$key] = $hash_credential_file[$key]
      end
    end
  end
end

# This function merges an additional file into the $$workflow_kv_store variable,
# it will overwrite existing keys. Its preferrable to initialize all in the beginning.
# Usage: 
# call kv_utils.merge("secret_bucket","base.json")
define merge($bucket, $object) do
  @additional_file = google_cloud_storage.objects.show(bucket_name: $bucket, object_name: $object)
  $response = @additional_file.content()
  $hash_additional_file = $response[0]
  foreach $key in keys($hash_additional_file) do
    $$workflow_kv_store[$key] = $hash_additional_file[$key]
  end
end

# This function is used to retrieve a value from the key value global variable $$workflow_kv_store
# Usage: 
# call kv_utils.get("username") retrieve $username
define get($key) return $value do
  $value = $$workflow_kv_store[$key]
end


operation "launch" do
  definition "launch"
end

define launch() return $username,$password,$sudo do
  call initialize("flexera-g-plugins-testing",["base.json","production.json"])
  call get("username") retrieve $username
  call get("password") retrieve $password
  call get("sudo") retrieve $sudo
end

define start_debugging() do
  if $$debugging == false || logic_and($$debugging != false, $$debugging != true)
    initiate_debug_report()
    $$debugging = true
  end
end

define stop_debugging() do
  if $$debugging == true
    $debug_report = complete_debug_report()
    call sys_log.detail($debug_report)
    $$debugging = false
  end
end