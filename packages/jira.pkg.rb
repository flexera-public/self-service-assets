name 'jira package'
rs_ca_ver 20160622
short_description 'Reusable bits for connecting to Jira'
import 'sys_log'
package 'integrations/jira'

output "out_jira_api_link" do
  label "Jira approval ticket API URL"
end

output "out_jira_issue_url" do
  label "Jira approval Issue URL"
end

define create_issue($jira_cookie) return $jira_link do
  $project = "PROJECT1"
  $issue_type = "Service Request"
  $deployment_values = split(@@deployment.name,'-')
  $server_name=join($deployment_values[0..-2], '-')
  $summary = "RightScale Request: "+$server_name

  # Fetch the user details
  $user_email = tag_value(@@deployment, 'selfservice:launched_by')
  if $user_email == null
    raise "Could not determine the email address of the user that launched the CloudApp"
  end
  @users = rs_cm.users.get(filter: ["email=="+$user_email])
  if size(@users) == 0
    raise "No user existed with the email address "+$user_email
  end
  @user = rs_cm.get(href: @users.href)
  $user_hash = to_object(@user)
  $user_email = $user_hash["details"][0]["email"]
  $user_principal_uid = "null"
  if contains?(keys($user_hash["details"][0]), ["principal_uid"])
    $user_principal_uid = $user_hash["details"][0]["principal_uid"]
  end

  # Fetch the template details
  $execution_href = tag_value(@@deployment, 'selfservice:href')
  @execution = rs_ss.get(href: $execution_href, view: 'expanded')
  $executions_hash = to_object(@execution)
  $execution_hash = $executions_hash["details"][0]
  $params = $execution_hash["configuration_options"]
  $cat_name = $execution_hash["launched_from_summary"]["value"]["name"]

  # get param values
  call get_params_value($params, 'param_environment') retrieve $param_environment
  #call get_params_value($params, 'param_location') retrieve $param_location
  call get_params_value($params, 'param_region') retrieve $param_region
  call get_params_value($params, 'param_instancetype') retrieve $param_instancetype
  call get_params_value($params, 'param_volume') retrieve $param_volume
  #call get_params_value($params, 'param_network') retrieve $param_network
  #call get_params_value($params, 'param_ip') retrieve $param_ip

  $description = "This was created in response to a request from RightScale Self-Service. Deployment: "+to_s(@@deployment.href)+"
Requested by email: "+$user_email+" principal_uid: "+$user_principal_uid+"

Project: " + $project +"
Issue Type: "+$issue_type+"
Launched from CAT: "+$cat_name+"
Launched at: "+ strftime(now(), '%Y-%m-%d %H:%M:%S UTC') +"

Configuration options selected:
Enviroment: " + $param_environment + "
Cloud:  VMware
Region: "+ $param_region+"
Instance Type: "+ $param_instancetype+"
Second Volume in GB: "+ $param_volume

  call log("Jira issue content", $description, "None")

  $response = http_post(
    # url: "https://jira-staging.example.com/rest/api/2/issue",
    url: "https://jira.example.com/rest/api/2/issue",
    body: { fields: {
      project: { key: $project },
      summary: $summary,
      description: $description,
      issuetype: { name: $issue_type},
      components: [{ name: "RightScale/CMP" }],
      reporter: {
        name: $user_email
      }
    }},
    headers: {
      "Content-Type": "application/json",
      "Cookie": "auth-openid="+$jira_cookie
    }
  )

  $body = $response["body"]
  $code = $response["code"]

  call log("Jira create response", to_s($code) + ":" + to_s($body), "None")

  $jira_link = $body["self"]
end

define get_issue_url($issue_link, $jira_cookie) return $issue_url do

  $response = http_get(
    url: $issue_link,
    headers: {
      "Content-Type": "application/json",
      "Cookie": "auth-openid="+$jira_cookie
    }
  )

  $body = $response["body"]

  $key = $body["key"]
  # $issue_url = "https://jira-staging.example.com/browse/" + $key
  $issue_url = "https://jira.example.com/browse/" + $key
end

define get_issue_state($issue_link, $jira_cookie) return $issue_state, $issue_resolution do

  $response = http_get(
    url: $issue_link,
    headers: {
      "Content-Type": "application/json",
      "Cookie": "auth-openid="+$jira_cookie
    }
  )

  $body = $response["body"]
  $code = $response["code"]

  call log("Jira issue state response", to_s($code) + ":" + to_s($body), "None")

  $issue_state = $body["fields"]["status"]["name"]
  $issue_resolution = "null"
  if $body["fields"]["resolution"]
    $issue_resolution = $body["fields"]["resolution"]["name"]
  end

end

define log($summary, $details, $notify) do
  rs_cm.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $summary, detail: $details})
end

define get_params_value($params, $name) return $value do
  foreach $param in $params do
    if $param['name']==$name
      $value = $param['value']
    end
   end
  if $value==null
    $value = "N/A"
  end
end

define add_issue_to_comment($jira_cookie, $issue_url, $comment) do
  $response = http_post(
    url: to_s($issue_url)+"/comment",
    body: { body: $comment },
    headers: {
      "Content-Type": "application/json",
      "Cookie": "auth-openid="+$jira_cookie
    }
  )

  $body = $response["body"]
  $code = $response["code"]

  call log("Jira comment response", to_s($code) + ":" + to_s($body), "None")

  $jira_link = $body["self"]
end
