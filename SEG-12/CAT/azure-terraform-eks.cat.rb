name 'Azure Compute Test CAT'
rs_ca_ver 20161221
short_description "Azure Compute - Test CAT"
import "sys_log"
import "azure/cloud_parameters"
import "plugins/azure_compute"
import "plugins/rs_azure_networking"

parameter "tenant_id" do
  like $cloud_parameters.tenant_id
  operations 'launch'
end

parameter "subscription_id" do
  like $cloud_parameters.subscription_id
  operations 'launch'
end
parameter 'region' do
  type 'string'
  label 'Region'
  operations 'launch'
end

parameter 'param_resource_group' do
  type 'string'
  label 'Resource Group'
  operations 'launch'
end

parameter 'param_virtual_network' do
  type 'string'
  label 'Virtual Network'
  operations 'launch'
end

parameter 'param_subnet' do
  type 'string'
  label 'Subnet'
  operations 'launch'
end

parameter "vmSize" do
  label "VirtualMachine Sizes"
  type "string"
  allowed_values "Standard_DS1_v2"
  default "Standard_DS1_v2"
end

permission "read_creds" do
  actions   "rs_cm.show_sensitive","rs_cm.index_sensitive"
  resources "rs_cm.credentials"
end

resource "azure_nic", type: "rs_azure_networking.interface" do
  name join(['linux-', last(split(@@deployment.href,"/"))])
  location $region
  resource_group $param_resource_group
  properties do {
    "ipConfigurations": [{
      "name": "ipconfig1",
      "properties": {
        "privateIPAllocationMethod": "Dynamic",
        "privateIPAddressVersion": "IPv4",
        "primary": true,
        "subnet": {
          "id": join(["subscriptions/", $subscription_id, "/resourceGroups/",$param_resource_group,"/providers/Microsoft.Network/virtualNetworks/",$param_virtual_network,"/subnets/",$param_subnet])
        }
      }
    }]
  } end
end

resource "server1", type: "azure_compute.virtualmachine" do
  name join(['tf-host-', last(split(@@deployment.href,"/"))])
  location $region
  resource_group $param_resource_group
  properties do {
    "hardwareProfile": {
      "vmSize": $vmSize
    },
    "osProfile": {
      "adminUsername": "rs-admin",
      "adminPassword": "Flexera1234!",
      "secrets": [],
      "computerName": "myVM",
      "linuxConfiguration": {
        "disablePasswordAuthentication": false
      }
    },
    "storageProfile": {
      "imageReference": {
        "sku": "16.04-LTS",
        "publisher": "Canonical",
        "version": "latest",
        "offer": "UbuntuServer"
      },
      "osDisk": {
        "caching": "ReadWrite",
        "managedDisk": {
          "storageAccountType": "Premium_LRS"
        },
        "name": join(["myVMosdisk", last(split(@@deployment.href,"/"))]),
        "createOption": "FromImage"
      }
    },
    "networkProfile": {
      "networkInterfaces": [{
        "id": @azure_nic.id
      }]
    }
  } end
end

resource "my_vm_extension", type: "azure_compute.extensions" do
  name join(["install-docker-", last(split(@@deployment.href, "/"))])
  resource_group $param_resource_group
  location $region
  virtualMachineName @server1.name
  properties do {
    "publisher" => "Microsoft.Azure.Extensions",
    "type" => "CustomScript",
    "typeHandlerVersion" => "2.1",
    "autoUpgradeMinorVersion" => true,
    "settings" => {
      "fileUris" => [ "https://s3.amazonaws.com/rightscale-services/terraform/install-docker-and-run-terraform-version.sh",
                      "https://s3.amazonaws.com/rightscale-services/terraform/download-tf-files.sh",
                      "https://s3.amazonaws.com/rightscale-services/terraform/docker-run-terraform-plan.sh"
                    ],
      "commandToExecute" => ""
    }
  } end
end

operation "launch" do
  description "Launch the application"
  definition "launch_handler"
end

define launch_handler($tenant_id, $subscription_id, @azure_nic, @server1, @my_vm_extension, $region) return @server1,@my_vm_extension do
  provision(@azure_nic)
  provision(@server1)
  $vm_extension = to_object(@my_vm_extension)
  $cmd = "
export ARM_CLIENT_ID="+ cred("ARM_CLIENT_ID") +"; \
export ARM_CLIENT_SECRET="+ cred("ARM_CLIENT_SECRET") +"; \
export ARM_SUBSCRIPTION_ID="+ cred("ARM_SUBSCRIPTION_ID") +"; \
export ARM_TENANT_ID="+ cred("ARM_TENANT_ID") +"; \
export ARM_ACCESS_KEY="+ cred("ARM_ACCESS_KEY") +"; \
export TF_VAR_location="+ $region +"; \
export TF_VAR_prefix=rstest; \
chmod +x *.sh
./install-docker-and-run-terraform-version.sh; \
./download-tf-files.sh;
./docker-run-terraform-plan.sh
"
  call sys_log.detail($vm_extension)
  $vm_extension["fields"]["properties"]["settings"]["commandToExecute"] = $cmd
  @my_vm_extension = $vm_extension
  provision(@my_vm_extension)
end
