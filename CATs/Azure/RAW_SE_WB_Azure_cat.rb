name 'RAW Flexera SE Workbench - Azure'
rs_ca_ver 20161221
short_description "Azure Hosted instance of the SE Workbench environment."
long_description "Multi volume host with internal virtual machines to provide an isolated environment."
import "sys_log"

resource "server1", type: "server" do
  name join(["SEWB-", last(split(@@deployment.href, "/"))])
  cloud "AzureRM Central US"
  server_template "SE-Workbench 2019"
  #multi_cloud_image_href "/api/multi_cloud_images/444219003"
  network "ss-cat-vpc"
  #subnets "DtlDEV-SEWB-LAB-Sub-flex"
  subnet_hrefs "/api/clouds/3526/subnets/1OT0AFUBE0PDG"
  instance_type "Standard_E4s_v3"
  security_groups "site-itasca-vpn"
  associate_public_ip_address true
end

operation "launch" do
 description "Launch the application"
 definition "launch_handler"
end

define launch_handler(@server1) return @server1,$vms,$vmss do
  call start_debugging()
  provision(@server1)
  call stop_debugging()
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
