name "Terraform Enterprise AWS CAT"
rs_ca_ver 20161221
short_description "Terraform Enterprise CAT"
import 'sys_log'

# Pretty inclusive set of permissions.
# TODO: group things down into smaller sets perhaps so admin isn't always needed, etc.
permission "pft_general_permissions" do
  resources "rs_cm.tags", "rs_cm.instances", "rs_cm.audit_entries", "rs_cm.credentials", "rs_cm.clouds", "rs_cm.sessions", "rs_cm.accounts", "rs_cm.publications"
  actions   "rs_cm.*"
end

permission "pft_sensitive_views" do
  resources "rs_cm.credentials" # Currently these actions are not support for instance resources, "rs_cm.instances"
  actions "rs_cm.index_sensitive", "rs_cm.show_sensitive"
end

parameter "param_hostname" do
  label "Hostname"
  type "string"
  default "server1"
end

parameter "param_instancetype" do
  category "Deployment Options"
  label "Server Performance Level"
  type "list"
  allowed_values "Standard Performance",
    "High Performance"
  default "Standard Performance"
end

parameter "param_business_unit" do
  label "Business Unit"
  type "string"
  allowed_values "Sales", "Engineering"
  default "Sales"
end

parameter "param_env" do
  label "Environment"
  type "string"
  allowed_values "Dev", "Prod"
end

parameter "param_branch" do
  label "Branch Name"
  type "string"
  default "master"
end

parameter "param_workspace_id" do
  label "Workspace Id"
  type "string"
  operations "queue_build"
end

output "output_workspace_id" do
  label "Workspace Id"
  category "Terraform"
  default_value $workspace_id
  description "Workspace Id"
end

output "output_workspace_href" do
  label "Workspace href"
  category "Terraform"
  default_value $workspace_href
  description "Workspace href"
end

output "output_workspace_url" do
  label "Workspace href"
  category "Terraform"
  default_value $workspace_url
  description "Workspace href"
end

output "output_cost_estimate" do
  label "Cost Estimate"
  category "Cost"
  description "Cost estimate from Terraform"
end

output "output_current_cost" do
  label "Estimated Current Cost"
  category "Cost"
end

operation "launch" do
  definition "defn_launch"
  output_mappings do {
    $output_workspace_id => $workspace_id,
    $output_workspace_href => $workspace_href,
    $output_workspace_url => $workspace_url,
    $output_current_cost => "0"
  } end
end

operation "queue_build" do
  definition "defn_queue_build"
  output_mappings do {
    $output_cost_estimate => $response_cost_estimate
  } end
end

operation "get_costs" do
  label "Get Costs"
  definition "defn_get_cost_data"
  output_mappings do {
    $output_current_cost => "1"
  } end
end

operation "stop" do
  definition "defn_stop"
end

operation "start" do
  definition "defn_start"
end

operation "terminate" do
  definition "defn_terminate"
end

mapping "map_instancetype" do {
  "Standard Performance" => {
    "AWS" => "t3.medium"
  },
  "High Performance" => {
    "AWS" => "t3.large"
  }
} end

define defn_launch($param_hostname, $param_business_unit, $param_env, $param_instancetype, $param_branch, $map_instancetype) return $workspace_href, $workspace_id, $workspace_url do
  $tf_cat_token = cred("TF_CAT_TOKEN")
  $base_url = "https://app.terraform.io/api/v2"
  $instance_type =  map($map_instancetype, $param_instancetype, "AWS")

  call defn_create_workspace($tf_cat_token,$base_url,"0.12.29",@@deployment,$param_branch) retrieve $workspace_href, $workspace_id
  call sys_log.detail(join(["Workspace ID: ", $workspace_id, ", HREF: ", $workspace_href]))
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "AWS_DEFAULT_REGION","us-east-2","AWS DEFAULT REGION", "env", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "AWS_ACCESS_KEY_ID", cred("AWS_ACCESS_KEY_ID"),"AWS ACCESS KEY", "env", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "AWS_SECRET_ACCESS_KEY", cred("AWS_SECRET_ACCESS_KEY"),"AWS_SECRET_ACCESS_KEY", "env", false, true)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "hostname", $param_hostname,"hostname of server", "terraform", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "tag_business_unit", $param_business_unit,"Business Unit of server", "terraform", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "tag_env", $param_env,"Environment of server", "terraform", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "instance_type",$instance_type,"Instance Type of server", "terraform", false, false)
  $workspace_url = join(["https://app.terraform.io/app/Flexera-SE/workspaces/", @@deployment.name, "/runs"])
end

define defn_stop() do
end

define defn_start() do
end

define defn_terminate() return $terminate_response do
  $tf_cat_token = cred("TF_CAT_TOKEN")
  $base_url = "https://app.terraform.io/api/v2"
  call defn_delete_workspace($tf_cat_token,$base_url,@@deployment.name) retrieve $terminate_response
end

define defn_queue_build($param_workspace_id) return $build_response,$response_cost_estimate do
  call defn_create_runs($param_workspace_id, false) retrieve $build_response,$response_cost_estimate
end

define defn_get_cost_data() return $cost do
end

define defn_create_workspace($tf_cat_token,$base_url,$tf_version,@deployment, $param_branch) return $workspace_href, $workspace_id do
  $workspace_href = ""
  $workspace_id = ""
  $response = http_post(
    headers: {
      "Authorization": join(["Bearer ", $tf_cat_token]),
      "Content-Type": "application/vnd.api+json",
      "content-type": "application/vnd.api+json"
    },
    body: {
      "type": "workspaces",
      "data": {
        "attributes": {
          "name": @deployment.name,
          "terraform-version": $tf_version,
          "working-directory": "Terraform/Terraform_Cloud/aws/",
          "vcs-repo": {
            "identifier": "flexera/self-service-assets",
            "display-identifier": "flexera/self-service-assets",
            "oauth-token-id": "ot-y778mKXqYLHfRrHh",
            "branch": $param_branch,
            "default-branch": true,
            "ingress-submodules": true,
            "file-triggers-enabled": false
          },
          "vcs-repo-identifier": "flexera/self-service-assets",
          "auto-apply": true
        }
      }
    },
    url: join([$base_url, "/organizations/Flexera-SE/workspaces"])
  )

  $$create_response = $response
  $$create_body = $response["body"]

  if to_s($response["code"]) =~ /20[0-9]/
    $workspace_href = $$create_body["data"]["links"]["self"]
    $workspace_id = $$create_body["data"]["id"]
  else
    raise to_s($$create_body)
  end
end

define defn_delete_workspace($tf_cat_token, $base_url, $name) return $response do
  $delete_url = join([$base_url, "/organizations/Flexera-SE/workspaces/", $name])
  call sys_log.detail(join(["Delete URL: ", to_s($delete_url)]))
  $get_response = http_get(
    headers: {
      "Authorization": join(["Bearer ", $tf_cat_token]),
      "Content-Type": "application/vnd.api+json",
      "content-type": "application/vnd.api+json"
    },
    url: $delete_url
  )
  call defn_create_runs($get_response["body"]["data"]["id"], true)
  $response = http_delete(
    headers: {
      "Authorization": join(["Bearer ", $tf_cat_token]),
      "Content-Type": "application/vnd.api+json",
      "content-type": "application/vnd.api+json"
    },
    url: $delete_url
  )
  call sys_log.detail(to_s($terminate_response))
end


define defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, $key, $value, $description, $category, $hcl, $sensitive) return $create_var_response do
  $var_url = join([$base_url, "/workspaces/", $workspace_id, "/vars"])
  call sys_log.detail($var_url)
  $create_var_response = http_post(
    headers: {
      "Authorization": join(["Bearer ", $tf_cat_token]),
      "Content-Type": "application/vnd.api+json",
      "content-type": "application/vnd.api+json"
    },
    body: {
      "data": {
        "type":"vars",
        "attributes": {
          "key": $key,
          "value": $value,
          "description": $description,
          "category": $category,
          "hcl": $hcl,
          "sensitive": $sensitive
        }
      }
    },
    url: $var_url
  )
  call sys_log.detail($create_var_response)
end

define defn_create_runs($param_workspace_id,$is_destroy) return $build_response,$response_cost_estimate do
  #https://github.com/hashicorp/terraform-guides/blob/master/operations/automation-script/loadAndRunWorkspace.sh#L262
  $tf_cat_token = cred("TF_CAT_TOKEN")
  $base_url = "https://app.terraform.io/api/v2"
  $build_response = http_post(
    headers: {
      "Authorization": join(["Bearer ", $tf_cat_token]),
      "Content-Type": "application/vnd.api+json",
      "content-type": "application/vnd.api+json"
    },
    body: {
      "data": {
        "attributes": {
          "auto-apply": true,
          "is-destroy": $is_destroy
        },
        "type":"runs",
        "relationships": {
          "workspace": {
            "data": {
              "type": "workspaces",
              "id": $param_workspace_id
            }
          }
        }
      }
    },
    url: join([$base_url, "/runs"])
  )
  call sys_log.detail($build_response)
  $cost_estimate = $build_response["body"]["data"]["relationships"]["cost-estimate"]
  if !equals?($cost_estimate, null)
    $cost_estimate_id = $cost_estimate["data"]["id"]
    $cost_estimate_href = $cost_estimate["links"]["related"]
    call sys_log.detail(join(["Cost Estimate Id: ", $cost_estimate_id, " Href: ", $cost_estimate_href]))
    $status = "pending"
    $cost_estimate_response = ""
    while $status != "finished" do
      sleep(20)
      $cost_estimate_response = http_get(
        headers: {
          "Authorization": join(["Bearer ", $tf_cat_token]),
          "Content-Type": "application/vnd.api+json"
        },
        url: join(["https://app.terraform.io", $cost_estimate_href])
      )
      call sys_log.detail($cost_estimate_response)
      $status = $cost_estimate_response["body"]["data"]["attributes"]["status"]
    end
    $response_cost_estimate = $cost_estimate_response["body"]["data"]["attributes"]["proposed-monthly-cost"]
  else
    $response_cost_estimate = "Upgrade Terraform Cloud to `Team & Governance` for this feature"
  end
  # Wait for run completion
  $run_status = "pending"
  $run_href = $build_response["body"]["data"]["links"]["self"]
  call sys_log.detail($run_href)
  while $run_status =~ "^(applied|errored|discarded)" do
    sleep(20)
    $run_response = http_get(
      headers: {
        "Authorization": join(["Bearer ", $tf_cat_token]),
        "Content-Type": "application/vnd.api+json"
      },
      url: join(["https://app.terraform.io", $run_href])
    )
    call sys_log.detail($run_response)
    $run_status = $run_response["body"]["data"]["attributes"]["status"]
  end
end
