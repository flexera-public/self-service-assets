name 'FlexNet Management Suite 2019 POC'
rs_ca_ver 20161221
short_description "Creates an FNMS POC server instance in a discrete VPC."
long_description "The FlexNet Management Suite 2019 POC CloudApp deploys a demo Microsoft Active Directory domain and FlexNet Managemwnt Platform environment.
The resources in this environment provide for the following use cases:
FlexNet Management Suite

You must be connected to the Flexera VPN or LAN to connect via RDP."

import "poc_clouds"
import "sys_log"
import "flex_vpn"
import "flex_lan"

mapping "map_flexlan" do
  like $flex_lan.map_flexlan
end
mapping "map_cloud" do
  like $poc_clouds.map_cloud
end
mapping "map_flexvpn" do
  like $flex_vpn.map_flexvpn
end

### Parameters: User Inputs ###
parameter "param_location" do
  type "string"
  label "AWS Region"
  category "Environment Options"
  description "Target region for this instance."
  allowed_values "US-East","US-West","US-Oregon","EU-Frankfurt","AP-Sydney","EU-Ireland","US-Ohio"
end
parameter "param_projectname" do
  type "string"
  label "Network Name"
  category "Environment Options"
  description "VPC nickname"
  allowed_values "Flexera","POC","TestTrack","Training"
  default "POC"
end
parameter "param_Network_Access" do
  category "Security"
  label "Allowed Network scope"
  description "CIDR range for allowed network (Web) traffic. Use 0.0.0.0/0 to not restrict access."
  type "string"
  default "0.0.0.0/0"
end
parameter "param_flexera_vpn" do
  category "Security"
  label "Flexera VPN"
  description "Select a Flexera VPN to grant RDP access."
  type "string"
  allowed_values "Itasca","Oakland","Maidenhead","Melbourne","Belfast","Bangalore"
  min_length 6
end
parameter "param_flexera_lan" do
  category "Security"
  label "Flexera LAN"
  description "Select a Flexera Location to grant RDP access."
  type "string"
  allowed_values "Itasca","Oakland Office","Maidenhead","Melbourne","Belfast","Bangalore","Oakland Digital Reality"
  min_length 6
end
parameter "param_purpose" do
  type "string"
  label "Purpose"
  category "Flexera"
  description "Select the enviromnent purpose"
  allowed_values "Flexera Demo","Flexera POC","Author","CSM","Partner Demo","Partner POC"
  default "Flexera POC"
end
parameter "param_solution" do
  type "string"
  label "Solution"
  category "Flexera"
  description "Select the Flexera Solution focus"
  allowed_values "FlexNet Management Suite","FlexNet Management for Engineering Applications","App Portal","Workflow Manager","AdminStudio","Data Platform","SVM 2018","Test Track"
  default "FlexNet Management Suite"
end
parameter "param_oppty" do
  type "string"
  label "Hero Request"
  category "Flexera"
  description "Enter the Hero request number."
  default "HR000"
end
###### Outputs #####
output "output_server_rdp" do
  label "RDP Address"
  category "Flexera VPN\LAN"
  default_value $server_access_link
end
output "output_server_url" do
  label "Public Url"
  category "Public Access"
  default_value join(["http://", $instance_ip, "/suite"])
end
### Resource Declarations:Servers ###
resource 'cat_server_fnms', type: 'server' do
  name join(["FNMS 2019 R1 POC-", last(split(@@deployment.href,"/"))])
  cloud map($map_cloud, $param_location, "cloud")
  datacenter map($map_cloud, $param_location, "datacenter")
  network @vpc_network
  subnets @vpc_subnet
  security_groups @project_sg
  server_template find("FNMS 2019 POC",revision:3)
  instance_type "t3.xlarge"
  #associate_public_ip_address "true"
end
resource "server_ip", type: "ip_address" do
  cloud map($map_cloud, $param_location, "cloud")
  name join(["EIP-", $param_projectname])
  domain "vpc"
  network @vpc_network
end
resource "server_ip_add", type: "ip_address_binding" do
  server @cat_server_fnms
  cloud map($map_cloud, $param_location, "cloud")
  public_ip_address @server_ip
end
### Resource Declarations:Network ###
resource "vpc_network", type: "network" do
  name join([$param_projectname,"-VPC"])
  cloud map($map_cloud, $param_location, "cloud")
  cidr_block "10.21.6.0/24"
end
resource "vpc_subnet", type: "subnet" do
  name join([$param_projectname,"-vpc-subnet"])
  description "Private VPC for the environment."
  cloud map($map_cloud, $param_location, "cloud")
  #All networking depends on the datacenter selected
  datacenter map($map_cloud, $param_location, "datacenter")
  network @vpc_network
  cidr_block "10.21.6.0/24"
end
resource "vpc_igw", type: "network_gateway" do
  name join([$param_projectname,"-igw"])
  cloud map($map_cloud, $param_location, "cloud")
  type "internet"
  network @vpc_network
end
resource "vpc_route_table", type: "route_table" do
  name join([$param_projectname,"-route-table"])
  cloud map($map_cloud, $param_location, "cloud")
  network @vpc_network
end
# Outbound traffic
resource "vpc_route", type: "route" do
  name join([$param_projectname,"-internet-route"])
  destination_cidr_block "0.0.0.0/0"
  next_hop_network_gateway @vpc_igw
  route_table @vpc_route_table
end
#Security Group for the CAT
resource 'project_sg', type: 'security_group' do
  name join([$param_projectname,"-security-group"])
  description "VPC security group"
  cloud map($map_cloud, $param_location, "cloud")
  network @vpc_network
end
# Network Access Parameter
resource 'project_sg_rule_HTTPS', type: 'security_group_rule' do
  name join([$param_projectname," HTTPS Rule"])
  description "HTTPS access rule"
  source_type "cidr_ips"
  security_group @project_sg
  protocol 'tcp'
  direction 'ingress'
  cidr_ips $param_Network_Access
  protocol_details do {
    'start_port' => '443',
    'end_port' => '443'
  } end
end
resource 'project_sg_rule_HTTP', type: 'security_group_rule' do
  name join([$param_projectname," HTTP Rule"])
  description "HTTP access rule"
  like @project_sg_rule_HTTPS
  protocol_details do {
    'start_port' => '80',
    'end_port' => '80'
  } end
end
resource 'project_sg_rule_FNMEA', type: 'security_group_rule' do
  name join([$param_projectname," FNMEA Rule"])
  description "FNMEA rule for demo SG"
  like @project_sg_rule_HTTPS
  protocol_details do {
  'start_port' => '8888',
  'end_port' => '8888'
  } end
end
resource 'project_sg_rule_WFM', type: 'security_group_rule' do
  name join([$param_projectname," Workflow Manager Rule"])
  description "WFM rule for demo SG"
  like @project_sg_rule_HTTPS
  protocol_details do {
  'start_port' => '81',
  'end_port' => '81'
  } end
end
###########################
# Flexera SG Rules - Flexera LAN
resource 'flexera_sg_rule_RDP_LAN', type: 'security_group_rule' do
  name join([$param_projectname," Flexera RDP Rule"])
  description "RDP access rule"
  source_type "cidr_ips"
  security_group @project_sg
  protocol 'tcp'
  direction 'ingress'
  cidr_ips map($map_flexlan,$param_flexera_lan,"cidr_ips")
  protocol_details do {
    'start_port' => '3389',
    'end_port' => '3389'
  } end
end
resource 'flexera_sg_rule_HTTPS_LAN', type: 'security_group_rule' do
  name join([$param_projectname," Flexera HTTP Rule"])
  description "HTTPS access rule"
  like @flexera_sg_rule_RDP_LAN
  protocol_details do {
    'start_port' => '443',
    'end_port' => '443'
  } end
end
resource 'flexera_sg_rule_HTTP_LAN', type: 'security_group_rule' do
  name join([$param_projectname," Flexera HTTPS Rule"])
  description "HTTP access rule"
  like @flexera_sg_rule_RDP_LAN
  protocol_details do {
    'start_port' => '80',
    'end_port' => '80'
  } end
end
resource 'flexera_sg_rule_FNMEA_LAN', type: 'security_group_rule' do
  name join([$param_projectname," Flexera FNMEA Rule"])
  description "FNMEA rule for demo SG"
  like @flexera_sg_rule_RDP_LAN
  protocol_details do {
  'start_port' => '8888',
  'end_port' => '8888'
  } end
end
resource 'flexera_sg_rule_WFM_LAN', type: 'security_group_rule' do
  name join([$param_projectname," Flexera Workflow Manager Rule"])
  description "WFM rule for demo SG"
  like @flexera_sg_rule_RDP_LAN
  protocol_details do {
  'start_port' => '81',
  'end_port' => '81'
  } end
end

###########################
# Flexera SG Rules - Flexera VPN
resource 'flexera_sg_rule_RDP', type: 'security_group_rule' do
  name join([$param_projectname," Flexera RDP Rule"])
  description "RDP access rule"
  source_type "cidr_ips"
  security_group @project_sg
  protocol 'tcp'
  direction 'ingress'
  cidr_ips map($map_flexvpn,$param_flexera_vpn,"cidr_ips")
  protocol_details do {
    'start_port' => '3389',
    'end_port' => '3389'
  } end
end
resource 'flexera_sg_rule_HTTPS', type: 'security_group_rule' do
  name join([$param_projectname," Flexera HTTP Rule"])
  description "HTTPS access rule"
  like @flexera_sg_rule_RDP
  protocol_details do {
    'start_port' => '443',
    'end_port' => '443'
  } end
end
resource 'flexera_sg_rule_HTTP', type: 'security_group_rule' do
  name join([$param_projectname," Flexera HTTPS Rule"])
  description "HTTP access rule"
  like @flexera_sg_rule_RDP
  protocol_details do {
    'start_port' => '80',
    'end_port' => '80'
  } end
end
resource 'flexera_sg_rule_FNMEA', type: 'security_group_rule' do
  name join([$param_projectname," Flexera FNMEA Rule"])
  description "FNMEA rule for demo SG"
  like @flexera_sg_rule_RDP
  protocol_details do {
  'start_port' => '8888',
  'end_port' => '8888'
  } end
end
resource 'flexera_sg_rule_WFM', type: 'security_group_rule' do
  name join([$param_projectname," Flexera Workflow Manager Rule"])
  description "WFM rule for demo SG"
  like @flexera_sg_rule_RDP
  protocol_details do {
  'start_port' => '81',
  'end_port' => '81'
  } end
end

###########################
#### Operations ###
operation 'start' do
  description 'Start the Server.'
  definition 'start'
  output_mappings do {
    $output_server_rdp => $server_access_link,
    $output_server_url => join(["http://",$instance_ip, "/suite"])
      } end
end
operation 'stop' do
  description 'Stop the Server.'
  definition 'stop'
end
operation 'launch' do
  description 'Create the VPC and Server Instances.'
  definition 'launch'
  output_mappings do {
    $output_server_url => join(["http://",$instance_ip, "/suite"]),
    $output_server_rdp => $server_access_link
  } end
end
operation 'terminate' do
  description 'Clean up the system.'
  definition 'terminate'
end
#### Definitions ####
define stop() do
  task_label("Stopping the servers in the CloudApp")
  @servers = rs_cm.servers.get(filter: ["deployment_href==" + @@deployment.href])
  @stoppable_servers = select(@servers, {state: "operational"})
  concurrent foreach @stoppable_server in @stoppable_servers do
      $wake_condition = "/^(stranded|stranded in booting|stopped|terminated|inactive|error|provisioned)$/"
      $stop_instance_retry = 0
      sub on_error: handle_retries($stop_instance_retry) do
        @stoppable_server.current_instance().stop()
        sleep_until(@stoppable_server.state =~ $wake_condition)
        $stop_instance_retry = $stop_instance_retry + 1
      end
  end
end

define start() do
  task_label("Starting the servers in the CloudApp")
  @servers = rs_cm.servers.get(filter: ["deployment_href==" + @@deployment.href])
  @startable_servers = select(@servers, {state: "provisioned"})
  concurrent foreach @startable_server in @startable_servers do
      $wake_condition = "/^(stranded|stranded in booting|terminated|inactive|error|operational)$/"
      $start_instance_retry = 0
      sub on_error: handle_retries($start_instance_retry) do
        @startable_server.current_instance().start()
        sleep_until(@startable_server.state =~ $wake_condition)
        $start_instance_retry = $start_instance_retry + 1
      end
    end
end

#The following definitions enumerate the account to identify the instance due to Self Service abstraction from CMP.
define find_shard() return $shard_number do
  $deployment_description = @@deployment.description
  $shard_number = "UNKNOWN"
  foreach $word in split($deployment_description, "/") do
    if $word =~ "selfservice-"
      foreach $character in split($word, "") do
        if $character =~ /[0-9]/
          $shard_number = $character
        end
      end
    end
  end
end
define find_account_number() return $rs_account_number do
  $cloud_accounts = to_object(first(rs_cm.cloud_accounts.get()))
  @info = first(rs_cm.cloud_accounts.get())
  $info_links = @info.links
  $rs_account_info = select($info_links, { "rel": "account" })[0]
  $rs_account_href = $rs_account_info["href"]
  $rs_account_number = last(split($rs_account_href, "/"))
end

define get_server_access_link(@server, $link_type, $shard, $account_number) return $server_access_link,$instance_ip do
  $rs_endpoint = "https://us-"+$shard+".rightscale.com"
  $instance_href = @server.current_instance().href
  $response = http_get(
    url: $rs_endpoint+"/api/instances",
    headers: {
    "X-Api-Version": "1.6",
    "X-Account": $account_number
    }
   )
  $instances = $response["body"]
  $instance_of_interest = select($instances, { "href" : $instance_href })[0]
  $legacy_id = $instance_of_interest["legacy_id"]
  $cloud_id = $instance_of_interest["links"]["cloud"]["id"]
  $instance_public_ips = $instance_of_interest["public_ip_addresses"]
  $instance_private_ips = $instance_of_interest["private_ip_addresses"]
  $instance_ip = switch(empty?($instance_public_ips), to_s($instance_private_ips[0]), to_s($instance_public_ips[0]))
  $server_access_link_root = "https://my.rightscale.com/acct/"+$account_number+"/clouds/"+$cloud_id+"/instances/"+$legacy_id
  if $link_type == "RDP"
    $server_access_link = $server_access_link_root +"/rdp?host=" + $instance_ip
  elsif $link_type == "SSH"
    $server_access_link = $server_access_link_root +"/managed_ssh.jnlp?host=" + $instance_ip
  else
    raise "Incorrect link_type, " + $link_type + ", passed to get_server_access_link()."
  end
end

# Launch will generate the VPC and create server instances.
# add additional server resources to the launch/return parameters.
define launch(@cat_server_fnms,@server_ip,@server_ip_add,$param_purpose,$param_oppty,$param_projectname,$param_solution,$map_cloud,$param_location,@vpc_network,@vpc_subnet,@vpc_igw,@vpc_route,@vpc_route_table,@flexera_sg_rule_HTTP_LAN,@flexera_sg_rule_RDP_LAN,@flexera_sg_rule_HTTPS_LAN,@flexera_sg_rule_WFM_LAN,@flexera_sg_rule_FNMEA_LAN,@flexera_sg_rule_HTTP,@flexera_sg_rule_RDP,@flexera_sg_rule_HTTPS,@flexera_sg_rule_WFM,@flexera_sg_rule_FNMEA,@project_sg,@project_sg_rule_HTTP,@project_sg_rule_HTTPS,@project_sg_rule_WFM,@project_sg_rule_FNMEA) return @cat_server_fnms,@server_ip,@server_ip_add,@vpc_network,@vpc_subnet,@vpc_igw,@vpc_route,@vpc_route_table,@project_sg,@flexera_sg_rule_HTTP,@flexera_sg_rule_RDP,@flexera_sg_rule_HTTPS,@flexera_sg_rule_WFM,@flexera_sg_rule_FNMEA,@project_sg_rule_HTTP,@project_sg_rule_HTTPS,@project_sg_rule_WFM,@project_sg_rule_FNMEA,$param_solution,$param_projectname,$param_purpose,$param_oppty,$map_cloud,$param_location,$server_access_link,$instance_ip do
  call sys_log.detail("Creating VPC")
  task_label("Generate Network VPC.")
  # create the VPC
  provision(@vpc_network)
  call sys_log.detail("VPC created")
  provision(@vpc_subnet)
  call sys_log.detail("Subnet created")
  provision(@project_sg)
  call sys_log.detail("Security group created")
  # create the Route and gateway for the VPC
  concurrent return @vpc_igw, @vpc_route_table do
    provision(@vpc_igw)
    call sys_log.detail("Internet gateway created")
    provision(@vpc_route_table)
    call sys_log.detail("Route Table created")
  end
  task_label("Attaching Route")
  provision(@vpc_route)
  task_label("Network Created")
  call sys_log.detail("VPC created")
  # configure the network to use the route table
  @vpc_network.update(network: {route_table_href: to_s(@vpc_route_table.href)})
  task_label("Provisioning External IP")
  call sys_log.detail("Provisioning External IP address.")
  provision(@server_ip)
  #Create the network security group
  task_label("Updating Security Groups")
  call sys_log.detail("Creating security group rules.")
  #Provision Flexera Security LAN group rule
  provision(@flexera_sg_rule_RDP_LAN)
  provision(@flexera_sg_rule_HTTP_LAN)
  provision(@flexera_sg_rule_HTTPS_LAN)
  provision(@flexera_sg_rule_WFM_LAN)
  provision(@flexera_sg_rule_FNMEA_LAN)
  #Provision Flexera Security VPN group rule
  provision(@flexera_sg_rule_RDP)
  provision(@flexera_sg_rule_HTTP)
  provision(@flexera_sg_rule_HTTPS)
  provision(@flexera_sg_rule_WFM)
  provision(@flexera_sg_rule_FNMEA)
  task_label("Created Flexera Security Groups")
  call sys_log.detail("Created Flexera Security Groups rules.")
  #Provision CAT Security group rules
  provision(@project_sg_rule_HTTP)
  provision(@project_sg_rule_HTTPS)
  provision(@project_sg_rule_WFM)
  provision(@project_sg_rule_FNMEA)
  task_label("Created Project Security Groups")
  call sys_log.detail("Created Project Security Groups rules.")
  task_label("All Security Group Rules created.")
  ######### Server Resources ###############
  task_label("Binding IP address to the FNMS Server")
  call sys_log.detail("Binding IP address to the FNMS Server")
  provision(@server_ip_add)
  task_label("Server Resources provisioned.")
  call sys_log.detail("Server Resources provisioned.")
  sleep_until(@cat_server_fnms.public_ip_addresses[0])
  call find_shard() retrieve $shard_number
  call find_account_number() retrieve $account_number
  call get_server_access_link(@cat_server_fnms, "RDP", $shard_number, $account_number) retrieve $server_access_link,$instance_ip
######### End Server Resources ###############
  task_label("Tagging Server with parameters.")
  call sys_log.detail("Tagging Server.")
  # Tag the servers with the selected Environment type.
  $tags=[join([map($map_cloud, $param_location, "tag_prefix"), ":Environment=",$param_projectname])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
  $tags=[join([map($map_cloud, $param_location, "tag_prefix"), ":Solution=",$param_solution])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
  $tags=[join([map($map_cloud, $param_location, "tag_prefix"), ":Purpose=",$param_purpose])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
  $tags=[join([map($map_cloud, $param_location, "tag_prefix"), ":Oppty=",$param_oppty])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
  call sys_log.detail("Tagging completed.")
  task_label("Complted Launch Operation.")
end

# Update some of the networking components to remove dependencies that would prevent cleaning up
# the network, such as servers, Ip addresses, etc.

define terminate(@cat_server_fnms,@server_ip,@vpc_route_table,@vpc_network) do
  # Terminate the servers in the network.
  delete(@cat_server_fnms)
  delete(@server_ip)
  # Switch back to the default route table so that auto-terminate doesn't hit a dependency issue when cleaning up.
  @other_route_table = @vpc_route_table #  initializing the variable
  # Find the route tables associated with our network.
  # There should be two: the one we created above and the default one that is created for new networks.
  @route_tables=rs_cm.route_tables.get(filter: [join(["network_href==",to_s(@vpc_network.href)])])
  foreach @route_table in @route_tables do
    if @route_table.href != @vpc_route_table.href
      # We found the default route table
      @other_route_table = @route_table
    end
  # Update the network to use the default route table
  @vpc_network.update(network: {route_table_href: to_s(@other_route_table.href)})
  end
end
