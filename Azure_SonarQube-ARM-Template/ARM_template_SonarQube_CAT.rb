name 'SonarQube Docker Web App on Linux with Azure SQL'
rs_ca_ver 20161221
short_description "SonarQube Docker Web App on Linux with Azure SQL"
import "plugins/rs_azure_template"

parameter "subscription_id" do
  like $rs_azure_template.subscription_id
end

parameter "param_location" do
  label "Azure Resource Location"
  type "string"
  category "Instance"
  allowed_values "centralus", "eastus", "eastus2", "westus", "northcentralus", "southcentralus", "westcentralus", "westus2"
  default "centralus"
end

parameter "param_site_name" do
  label "Site Name"
  type "string"
  category "Instance"
  allowed_pattern /^[ a-zA-Z0-9_-]*$/
  min_length 3
  max_length 50
end

parameter "param_sq_image_version" do
  label "SonarQube Image Version"
  type "string"
  category "Instance"
  allowed_values "latest", "lts", "7.9-community", "7.8-community", "7.7-community", "7.6-community", "7.5-community", "7.4-community", "7.1", "7.0", "alpine", "lts-alpine", "6.7.5", "6.7.4", "6.7.3", "6.7.2", "6.7.1"
  default "lts"
end

parameter "param_serviceplan_pricing_tier" do
  label "App Service Plan Pricing Tier"
  type "string"
  category "Instance"
  allowed_values "B1", "B2", "B3", "S1", "S2", "S3", "P1V2", "P2V2", "P2V3"
  default "S2"
end

parameter "param_serviceplan_capacity" do
  label "App Service Capacity"
  type "number"
  category "Instance"
  min_value 1
  max_value 3
  default 1
  constraint_description "Enter a value between 1-3."
end

parameter "param_sqladmin_username" do
  label "Azure SQL Server Administrator Username"
  type "string"
  category "SQL"
  allowed_pattern /^[ a-zA-Z0-9_-]*$/
  min_length 3
  max_length 50
end

parameter "param_sql_password" do
  type "string"
  no_echo true
  label "Azure SQL Server Administrator Password"
  category "SQL"
  min_length 8
end

parameter "param_sql_sku_name" do
  label "Azure SQL Database SKU Name"
  type "string"
  category "SQL"
  allowed_values "GP_Gen4_1", "GP_Gen4_2", "GP_Gen4_3", "GP_Gen4_4", "GP_Gen4_5", "GP_Gen4_6", "GP_Gen4_7", "GP_Gen4_8", "GP_Gen4_9", "GP_Gen4_10", "GP_Gen4_16", "GP_Gen4_24", "GP_Gen5_2", "GP_Gen5_4", "GP_Gen5_6", "GP_Gen5_8", "GP_Gen5_10", "GP_Gen5_12", "GP_Gen5_14", "GP_Gen5_16", "GP_Gen5_18", "GP_Gen5_20", "GP_Gen5_24", "GP_Gen5_32", "GP_Gen5_40", "GP_Gen5_80", "GP_S_Gen5_1", "GP_S_Gen5_2", "GP_S_Gen5_4"
  default "GP_S_Gen5_2"
end

parameter "param_sql_database_size" do
  label "Azure SQL Database Storage Max Size in GB"
  type "number"
  category "SQL"
  min_value 1
  max_value 1024
  default 16
  constraint_description "Enter a value between 1-1024."
end

resource "my_template", type: "rs_azure_template.deployment" do
  name join(["SS-test", last(split(@@deployment.href, "/"))])
  resource_group "SS-ARM-Testing"
  properties do {
    "templateLink" => { 
      "uri" => "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-webapp-linux-sonarqube-azuresql/azuredeploy.json" },
    "parameters" => "",
    "mode" => "Incremental"
  } end
end 

operation "launch" do
  definition "launch"
end 

define launch(@my_template) return @my_template do
  call get_arm_template_params() retrieve $params
  $object = to_object(@my_template)
  $object["fields"]["properties"]["parameters"] = $params
  @my_template = $object
  provision(@my_template)
end 

define get_arm_template_params() return $params do
  $params = {
    "location": {
      "value": param_location
    },
    "siteName": {
        "value": param_site_name
    },
    "sonarqubeImageVersion": {
        "value": param_sq_image_version
    },
    "servicePlanPricingTier": {
        "value": param_serviceplan_pricing_tier
    },
    "sqlServerAdministratorUsername": {
        "value": param_sqladmin_username
    },
    "sqlServerAdministratorPassword": {
      "value": param_sql_password
    },
    "sqlDatabaseSkuName": {
      "value": param_sql_sku_name
    },
    "sqlDatabaseSkuSizeGB": {
      "value": param_sql_database_size
    } 
}
end 