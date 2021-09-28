# Deploy to Amazon
# Parameter based on cheapest region

# tag CostCenter=1234
# tag BusinessUnit=SRE
# Billing Center -> CloudCoE
# Billing Center -> Demo
name "FlexeraOne Sales Demo"
rs_ca_ver 20161221
short_description "FlexeraOne Sales Demo"
import 'sys_log'
import "plugin/aws_compute"

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

parameter 'param_region' do
  type 'string'
  label 'AWS Region'
  default "us-east-2"
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
  default "Dev"
end

parameter "param_branch" do
  label "Branch Name"
  type "string"
  default "master"
end

parameter "param_workspace_id" do
  label "Workspace Id"
  type "string"
end

output "output_workspace_url" do
  label "Workspace"
  category "Terraform"
  default_value $workspace_url
  description "Workspace"
end

output "output_terraform_outputs" do
  label "Terraform Outputs"
  category "Terraform"
end

output "output_billing_center" do
  label "Billing Center"
  category "Cost"
end

output "output_cost_estimate" do
  label "Cost Estimate from Terraform"
  category "Cost"
  description "Cost estimate from Terraform"
end

output "output_current_cost" do
  label "Estimated Total Cost"
  category "Cost"
end

output "output_last_month_cost" do
  label "Estimated Last Month Cost"
  category "Cost"
end

output "output_this_month_cost" do
  label "Estimated This Month Cost"
  category "Cost"
end

output "output_workspace_id" do
  label "Workspace Id"
  category "Debug"
  default_value $workspace_id
  description "Workspace Id"
end

output "output_workspace_href" do
  label "Workspace href"
  category "Debug"
  default_value $workspace_href
  description "Workspace href"
end

operation "launch" do
  definition "defn_launch"
  output_mappings do {
    $output_workspace_id => $workspace_id,
    $output_workspace_href => $workspace_href,
    $output_workspace_url => $workspace_url,
    $output_current_cost => "0",
    $output_cost_estimate => $response_cost_estimate,
    $output_terraform_outputs => $tf_outputs
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
    $output_current_cost => $cost,
    $output_last_month_cost => $last_month_cost,
    $output_this_month_cost => $this_month_cost,
    $output_billing_center => $bc_markdown
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

define defn_launch($param_hostname, $param_business_unit, $param_env, $param_instancetype, $param_branch, $map_instancetype, $param_region) return $workspace_href, $workspace_id, $workspace_url, $response_cost_estimate, $tf_outputs do
  $tf_cat_token = cred("TF_CAT_TOKEN")
  $base_url = "https://app.terraform.io/api/v2"
  $instance_type =  map($map_instancetype, $param_instancetype, "AWS")

  call defn_create_workspace($tf_cat_token,$base_url,"0.12.29",@@deployment,$param_branch) retrieve $workspace_href, $workspace_id
  call sys_log.detail(join(["Workspace ID: ", $workspace_id, ", HREF: ", $workspace_href]))
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "AWS_DEFAULT_REGION",$param_region,"AWS DEFAULT REGION", "env", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "AWS_ACCESS_KEY_ID", cred("AWS_ACCESS_KEY_ID"),"AWS ACCESS KEY", "env", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "AWS_SECRET_ACCESS_KEY", cred("AWS_SECRET_ACCESS_KEY"),"AWS_SECRET_ACCESS_KEY", "env", false, true)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "hostname", $param_hostname,"hostname of server", "terraform", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "tag_business_unit", $param_business_unit,"Business Unit of server", "terraform", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "tag_env", $param_env,"Environment of server", "terraform", false, false)
  call defn_create_workspace_var($tf_cat_token, $base_url, $workspace_id, "instance_type",$instance_type,"Instance Type of server", "terraform", false, false)
  $workspace_url = join(["https://app.terraform.io/app/Flexera-SE/workspaces/", @@deployment.name])
  call defn_queue_build($workspace_id) retrieve $build_response,$response_cost_estimate
  call defn_get_workspace_outputs($workspace_id) retrieve $outputs
  $tf_outputs = to_s($outputs)
  $time = now() + (60*2)
  rs_ss.scheduled_actions.create(
                                  execution_id:       @@execution.id,
                                  name:               "Checking for Cost Data",
                                  action:             "run",
                                  operation:          { "name": "get_costs" },
                                  first_occurrence:   $time,
                                  recurrence:         "FREQ=HOURLY;INTERVAL=1"
                                )
end

define defn_stop($param_region) do
  call defn_get_workspace_id() retrieve $workspace_id
  call defn_get_workspace_outputs($workspace_id) retrieve $outputs
  $instance_id = $outputs["instance_resource_id"]
  $str = join([$outputs,$instance_id],"-")
  call sys_log.detail($str)
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    @instance = aws_compute.instances.show(instance_id: $instance_id)
    @instance.stop()
  end
  call aws_compute.stop_debugging()
end

define defn_start($param_region) do
  call defn_get_workspace_id() retrieve $workspace_id
  call defn_get_workspace_outputs($workspace_id) retrieve $outputs
  $instance_id = $outputs["instance_resource_id"]
  $str = join([$outputs,$instance_id],"-")
  call sys_log.detail($str)
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    @instance = aws_compute.instances.show(instance_id: $instance_id)
    @instance.start()
  end
  call aws_compute.stop_debugging()
end

define defn_terminate() return $terminate_response do
  $tf_cat_token = cred("TF_CAT_TOKEN")
  $base_url = "https://app.terraform.io/api/v2"
  call defn_delete_workspace($tf_cat_token,$base_url,@@deployment.name) retrieve $terminate_response
end

define defn_get_workspace_id() return $workspace_id do
  @execution = @@execution.show(view: "expanded")
  $execution = to_object(@execution)
  $outputs = $execution["details"][0]["outputs"]
  $output_workspace_id = first(select($outputs, { "name": "output_workspace_id" }))
  $workspace_id = $output_workspace_id["value"]["value"]
end

define defn_queue_build($param_workspace_id) return $build_response,$response_cost_estimate do
  call defn_create_runs($param_workspace_id, false) retrieve $build_response,$response_cost_estimate
end

define defn_get_cost_data($map_instancetype, $param_instancetype, $param_region) return $response, $price, $cost, @execution, $execution, $difference_in_hours, $last_month_cost, $this_month_cost, $bc_markdown do
  @execution = @@execution.show(view: "expanded")
  $execution = to_object(@execution)
  $execution_details = first($execution["details"])
  $outputs = $execution_details["outputs"]
  $output_terraform_outputs = first(select($outputs, { "name": "output_terraform_outputs" }))
  $output_value = $output_terraform_outputs["value"]["value"]
  $resource_id = from_json($output_value)["instance_resource_id"]
  $project = $execution_details["project"]["id"]
  $org_id = $execution_details["project"]["org_id"]
  if $org_id == 6
    $org_id = 78
  end
  $headers = {"Api-Version": "1.0"}
  $response = http_get({
     headers: $headers,
     url: join(["https://optima.rightscale.com/analytics/orgs/",$org_id,"/billing_centers?view=allocation_table"])
  })
  $billing_centers = []
  foreach $i in $response["body"] do
   if !contains?(keys($i), ["parent_id"])
     $billing_centers << $i["id"]
   end
  end
  $timestamps = $execution_details["timestamps"]
  $now = now()
  $launched_at = to_d($timestamps["launched_at"])
  $format_string = "%Y-%m"
  $launched_at_monthly = strftime($launched_at, $format_string)
  $now_monthly = strftime($now,$format_string)
  $month = to_n(strftime($now,"%-m"))
  $year = strftime($now,"%Y")
  $launched_at_month = to_n(strftime($launched_at,"%-m"))

  if $launched_at_month == $month
    if $month == 12
      $next_month = 1
      $next_year = to_n($year) + 1
    else
      $next_month = $month + 1
      $next_year = $year
    end
    $cost_month = $next_month
  else
    $next_year = $year
    $cost_month = $month
  end
  if $cost_month <= 9
    $cost_month_padded = join([$next_year,"-0",to_s($cost_month)])
  else
    $cost_month_padded = join([$next_year, "-", to_s($cost_month)])
  end

  call sys_log.detail(join(["getting cost data for ", $launched_at_monthly, "-> ", $cost_month_padded]))
  call get_resource_optima_data($headers,$billing_centers,$resource_id,$launched_at_monthly,$cost_month_padded,$org_id) retrieve $cost, $billing_center_id, $billing_center_url, $billing_center_name, $bc_markdown

  if $month == 1
    $last_month = 12
    $last_year = to_n($year) - 1
  else
    $last_month = $month - 1
    $last_year = $year
  end
  if $last_month <= 9
    $last_month_padded = join([$last_year,"-0",to_s($last_month)])
  else
    $last_month_padded = join([$last_year, "-", to_s($last_month)])
  end
  call sys_log.detail(join(["getting cost data for ", $last_month_padded, "-> ", $now_monthly]))
  call get_resource_optima_data($headers,$billing_centers,$resource_id,$last_month_padded,$now_monthly,$org_id) retrieve $last_month_cost, $billing_center_id, $billing_center_url, $billing_center_name, $bc_markdown

  if $month == 12
    $next_month = 1
    $next_year = to_n($year) + 1
  else
    $next_month = $month + 1
    $next_year = $year
  end
  if $next_month <= 9
    $next_month_padded = join([$next_year,"-0",to_s($next_month)])
  else
    $next_month_padded = join([$next_year, "-", to_s($next_month)])
  end
  call sys_log.detail(join(["getting cost data for ", $now_monthly, "-> ", $next_month_padded]))
  call get_resource_optima_data($headers,$billing_centers,$resource_id,$now_monthly,$next_month_padded,$org_id) retrieve $this_month_cost, $billing_center_id, $billing_center_url, $billing_center_name, $bc_markdown
  if $cost <= 0
    $difference = $now -$launched_at
    $difference_in_hours = ($difference/60)/60
    $instance_type =  map($map_instancetype, $param_instancetype, "AWS")
    $response = http_post(
      headers:{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Connection': 'keep-alive',
        'DNT': '1',
        'Origin': 'http://34.121.248.201'
      },
      body: { "query": "query { products( filter: { vendorName: \"aws\", service: \"AmazonEC2\", productFamily: \"Compute Instance\", region: \""+$param_region+"\", attributeFilters: [   { key: \"instanceType\", value: \""+$instance_type+"\" },   { key: \"tenancy\", value: \"Shared\" },   { key: \"operatingSystem\", value: \"Linux\" },   { key: \"capacitystatus\", value: \"Used\" },   { key: \"preInstalledSw\", value: \"NA\" } ]},) {prices( filter: {   purchaseOption: \"on_demand\" },) { USD }}}"},
      url: "http://34.121.248.201/graphql"
    )
    $price = $response["body"]["data"]["products"][0]["prices"][0]["USD"]

    if $difference_in_hours < 1
      $cost = $price
    else
      $cost = to_n($price) * $difference_in_hours
    end
  end
  $cost = to_s($cost)
  if $this_month_cost == 0
    $this_month_cost = $cost
  else
    $this_month_cost = to_s($this_month_cost)
  end
  $last_month_cost = to_s($last_month_cost)
end

define get_resource_optima_data($headers,$billing_centers,$resource_id,$start_at,$end_at,$org_id) return $cost, $billing_center_id, $billing_center_url, $billing_center_name, $bc_markdown do
  $query = {
   "billing_center_ids" => [],
   "dimensions"=> [
     "resource_id",
     "billing_center_id"
   ],
   "end_at" => $end_at,
   "filter" => {
     "dimension"=> "resource_id",
     "type" => "equal",
     "value" => $resource_id
   },
   "granularity" => "month",
   "limit" => 100000,
   "metrics" => [
     "cost_amortized_blended_adj"
   ],
   "start_at" => $start_at
  }
  $query["billing_center_ids"] = $billing_centers
  $analysis_response = {}
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    $analysis_response = http_post(
      headers: $headers,
      url: "https://optima.rightscale.com/bill-analysis/orgs/78/costs/select",
      body: $query
    )
  end
  call aws_compute.stop_debugging()
  $cost = 0
  $bc_markdown = "[Optima](https://analytics.rightscale.com/)"
  $rows = $analysis_response["body"]["rows"]
  if size($rows) > 0
    $billing_center_id = first($analysis_response["body"]["rows"])["dimensions"]["billing_center_id"]
    $billing_center_name = first(select($response["body"], {"id": $billing_center_id}))["name"]
    $billing_center_url = join(["https://analytics.rightscale.com/orgs/",$org_id,"/billing/billing-centers/", $billing_center_id, "/dashboard/default"])
    $bc_markdown=join(["[",$billing_center_name,"](",$billing_center_url,")"])
    $cost = 0
    foreach $row in $analysis_response["body"]["rows"] do
      $cost = $cost + to_n($row["metrics"]["cost_amortized_blended_adj"])
    end
  end
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
  while $run_status !~ "^(applied|errored|discarded)" do
    sleep(5)
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

define defn_get_workspace_outputs($param_workspace_id) return $outputs do
  $tf_cat_token = cred("TF_CAT_TOKEN")
  $base_url = "https://app.terraform.io/api/v2/workspaces/"
  $url = join([$base_url,$param_workspace_id,"/current-state-version?include=outputs"])
  call sys_log.detail($url)
  $output_response = http_get(
    headers: {
      "Authorization": join(["Bearer ", $tf_cat_token]),
      "Content-Type": "application/vnd.api+json",
      "content-type": "application/vnd.api+json"
    },
    url: $url
  )
  call sys_log.detail($output_response)
  $outputs_array = $output_response["body"]["included"]
  $outputs = {}
  foreach $item in $outputs_array do
    $key = $item["attributes"]["name"]
    $value = $item["attributes"]["value"]
    $outputs[$key] = $value
  end
end
