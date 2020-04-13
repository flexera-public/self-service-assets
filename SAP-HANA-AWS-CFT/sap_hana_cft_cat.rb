name "SAP HANA CFT Deployment CAT"
rs_ca_ver 20161221
short_description  "SAP HANA CFT Deployment CAT"
long_description "This CAT deploys SAP HANA on AWS using the AWS Cloud Formation template"

import "plugins/rs_aws_cft"


parameter "vpc_cidr" do
  type "string"
  label "VPC"
  default "10.0.0.0/16"
  allowed_pattern "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(1[6-9]|2[0-8]))$"
  constraint_description "Please Enter CIDR block for Amazon VPC"
end

parameter "hana_install_media" do
  type "string"
  label "Install Media"
  constraint_description "Full path to Amazon S3 location of SAP HANA software files (e.g.,
  s3://myhanabucket/sap-hana-sps11/)"
end  

parameter "availability_zone" do
  type "string"
  label "availability zone"
  default "AWS::EC2::AvailabilityZone::Name"
  constraint_description "The Availability Zone where SAP HANA subnets will be created"
end
        
parameter "auto_recovery" do
  type "string"
  label "SAP HANA Recovery Options"
  default "Yes"
  allowed_values "Yes", "No"
  constraint_description "Enable (Yes) or disable (No) automatic recovery feature for SAP HANA
  nodes. Disable it for Dedicated Host Deployments."
end

parameter "aws_efs" do
  type "string"
  label "AWS EFS"
  default "Yes"
  allowed_values "Yes", "No"
  constraint_description "Use (Yes) or don't use (No) Amazon EFS for HANA shared file system."
end
               
parameter "encryption" do
  type "string"
  label "Encryption"
  default "No"
  allowed_values "Yes", "No"
  constraint_description ""
end

parameter "dmz_cidr" do
  type "string"
  label "VPC"
  default "10.0.2.0/24"
  allowed_pattern "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(1[6-9]|2[0-8]))$"
  constraint_description "CIDR block for the public DMZ subnet located in the new VPC"
end

parameter "priv_sub_cidr" do
  type "string"
  label "VPC"
  default "10.0.1.0/24"
  allowed_pattern "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(1[6-9]|2[0-8]))$"
  constraint_description "CIDR block for the private subnet where SAP HANA will be deployed."
end

parameter "remote_access_cidr" do
  type "string"
  label "VPC"
  default "0.0.0.0/0"
  #allowed_pattern "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(1[6-9]|2[0-8]))$"
  constraint_description "CIDR block from where you want to access your bastion and RDP instances. This must be a valid CIDR range in the format x.x.x.x/x."
end

parameter "application_cidr" do
  type "string"
  label "VPC"
  default "0.0.0.0/0"
  #allowed_pattern "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(1[6-9]|2[0-8]))$"
  constraint_description "CIDR block of subnet where SAP Application servers are deployed. This must be a valid CIDR range in the format x.x.x.x/x."
end

parameter "key_name" do
  type "string"
  label "SSH Key Name"
  default "default"
end

parameter "bastion_instance_type" do
  type "string"
  label "BASTION Instance type"
  default "t2.small"
  allowed_values "t2.small","t2.large","m5.large","c5.large"
  constraint_description "Amazon EC2 instance type for the bastion host."
end

parameter "domain_name" do
  type "string"
  label "Domain Name"
  default "local"
  constraint_description "Name to use for fully qualified domain names"
end

parameter "hana_master_hostname" do
  type "string"
  label "Master Host Name"
  default "imdbmaster"
  constraint_description "Host name to use for SAP HANA master node (DNS short name)."
end

parameter "hana_worker_hostname" do
  type "string"
  label "Worker Host Name"
  default "imdbworker"
  constraint_description "Host name to use for SAP HANA worker node(s) (DNS short name)."
end

parameter "placement_group_name" do
  type "string"
  label "Placement group"
  constraint_description "Name of an existing placement group where SAP HANA should be deployed
  (for scale-out deployments)."
end

parameter "private_bucket" do
  type "string"
  label "S3 bucket"
  default "aws-quickstart/quickstart-sap-hana"
  constraint_description "Main build bucket where templates and scripts are located."
end

parameter "custom_storage_config" do
  type "string"
  label "Storage Config"
  default "aws-quickstart/quickstart-sap-hana/scripts"
  constraint_description "S3 location where custom storage configuration file is localted."
end

parameter "proxy" do
  type "string"
  label "Proxy"
  default ""
  constraint_description "Proxy address for http access (e.g., http://xyz.abc.com:8080 or http://10.x.x.x:8080)"
end

parameter "enable_logging" do
  type "string"
  label "Enable Logging"
  default "No"
  allowed_values "Yes", "No"
  constraint_description "Enable (Yes) or disable (No) logging with AWS CloudTrail and AWS
  Config."
end

parameter "cloud_trail_s3_bucket" do
  type "string"
  label "Cloud trail S3 bucket"
  default ""
  constraint_description "Name of S3 bucket where AWS CloudTrail trails and AWS Config log
  files can be stored (e.g., mycloudtrail)."
end

parameter "my_os" do
  type "string"
  label "Operating system"
  default "SuSELinux12SP4ForSAP"
  allowed_values "SuSELinux12SP4ForSAP", "RedHatLinux76ForSAP-With-HA-US"
  constraint_description "Operating system (SLES or RHEL) and version for master/worker nodes"
end

parameter "my_instance_type" do
  type "string"
  label "Instance Type"
  default "r5.2xlarge"
  allowed_values "r5.2xlarge", "r5.24xlarge","x1e.32xlarge","u-24tb1.metal"
  constraint_description "Instance type for SAP HANA host."
end

parameter "rdp_instance_type" do
  type "string"
  label "RDP Instance type"
  default "c5.large"
  allowed_values "c5.large", "m4.xlarge","m5.xlarge"
  constraint_description "Instance type for Windows RDP instance"
end

parameter "install_rdp_instance" do
  type "string"
  label "RPD Instance"
  default "No"
  allowed_values "Yes", "No"
  constraint_description "Install (Yes) or don't install (No) optional Windows RDP instance."
end

parameter "install_hana" do
  type "string"
  label "INstall HANA"
  default "Yes"
  allowed_values "Yes", "No"
  constraint_description "Install (Yes) or don't install (No) HANA. When set to No, only AWS
  infrastructure is provisioned."
end

parameter "dedicated_host_id" do
  type "list"
  label "HOst ID"
  constraint_description "Existing dedicated host(s) where you want to launch your EC2 instance(s).
  Use comma to provide multiple hosts. Mandatory for Amazon EC2 High Memory Instances."
end

parameter "host_count" do
  type "string"
  label "Host Count"
  default "1"
  allowed_values "1", "2","3","4","5"
  constraint_description "Total number of SAP HANA nodes you want to deploy in the SAP HANA"
end

parameter "sid" do
  type "string"
  label "SID"
  default "HDB"
  allowed_pattern "([A-Z]{1}[0-9A-Z]{2})"
  constraint_description "SAP HANA system ID for installation and setup. This value must consist of 3 characters."
end

parameter "sap_instance_num" do
  type "string"
  label "Number of SAP instances"
  default "00"
  allowed_pattern "([0-8]{1}[0-9]{1}|[9]{1}[0-7]{1})"
  constraint_description "SAP HANA instance number to use for installation and setup, and to
  open ports for security groups.Instance number must be between 00 and 97."
end

parameter "hana_master_pass" do
  type "string"
  label "PASSWORD for SAP HANA"
  default "Xjava123"
  allowed_pattern "^(?=.*?[a-z])(?=.*?[A-Z])(?=.*[0-9]).*"
  constraint_description "SAP HANA password to use during installation. Must be at least 8
  characters with uppercase, lowercase, and numeric values.This must be at least 8 characters, including uppercase,
  lowercase, and numeric values."
end

parameter "volume_type_hana_data" do
  type "string"
  label "Data Volume Type"
  default "gp2"
  allowed_values "gp2","io1"
  constraint_description "EBS volume type for SAP HANA Data: General Purpose SSD (gp2) or
  Provisioned IOPS SSD (io1)."
end

parameter "volume_type_hana_log" do
  type "string"
  label "Log Volume Type"
  default "gp2"
  allowed_values "gp2","io1"
  constraint_description "EBS volume type for SAP HANA Data: General Purpose SSD (gp2) or
  Provisioned IOPS SSD (io1)."
end

parameter "saptz" do
  type "string"
  label "Time Zone"
  default "CT"
  allowed_values "CT","ET","PT","JT","UC"
  constraint_description "The TimeZone of your SAP HANA Server (PT, CT, ET, or UTC). This value must consist of 2 characters."
end

parameter "sles_byos_reg_Code" do
  type "string"
  label "Your license regestration code"
  default "CT"
  constraint_description "Registration code for SUSE BYOS (Applicable only if you use BYOS
  Option)."
end

parameter "qs_s3_bucket_name" do
  type "string"
  label "S3 bucket name"
  default "aws-quickstart"
  allowed_pattern "^[0-9a-zA-Z]+([0-9a-zA-Z-]*[0-9a-zA-Z])*$"
  constraint_description "S3 bucket name for the Quick Start assets. Quick Start bucket name
  can include numbers, lowercase letters, uppercase letters, and hyphens (-).
  It cannot start or end with a hyphen (-)."
end

parameter "qs_s3_bucket_region" do
  type "string"
  label "S3 bucket region"
  default "us-east-1"
  constraint_description "The AWS Region where the Quick Start S3 bucket (QSS3BucketName) is hosted. When using your own bucket, you must specify this value."
end

parameter "qs_s3_key_prefix" do
  type "string"
  label "S3 bucket prefix"
  default "quickstart-sap-hana/"
  allowed_pattern "^[0-9a-zA-Z-/]*$"
  constraint_description "S3 key prefix for the Quick Start assets. Quick Start key prefix
  can include numbers, lowercase letters, uppercase letters, hyphens (-), and
  forward slash (/)."
end


resource "stack", type: "rs_aws_cft.stack" do
  stack_name join(["cft-", last(split(@@deployment.href, "/"))])
  capabilities "CAPABILITY_IAM"
  template_body ""
  description "SAP HANA"
end

operation "launch" do
  description "Launch the application"
  definition "launch_handler"
end

define launch_handler(@stack,$vpc_cidr,$hana_install_media) return $cft_template,@stack do
  call generate_cloudformation_template($vpc_cidr,$hana_install_media) retrieve $cft_template
  task_label("provision CFT Stack")
  $stack = to_object(@stack)
  $stack["fields"]["template_body"] = $cft_template
  @stack = $stack
  provision(@stack)
  $output_keys = @stack.OutputKey
  $output_values = @stack.OutputValue
  
  $i = 0
  foreach $output_key in $output_keys do
    if $output_key == "DomainName"
      $domain_name = $output_values[$i]
    elsif $output_key == "AnotherOutput"  # this will fire given the CFT example. Provided as an example bit of code.
      $another_output = $output_values[$i]
    end
    $i = $i + 1
    end
end

# Example CFT
define generate_cloudformation_template($vpc_cidr,$hana_install_media) return $cft_template do
  $cft_template = to_s('{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "Deploy AWS infrastructure and SAP HANA on AWS",
  "Parameters": {
    "VPCCIDR": {
      "Description": "CIDR block for the Amazon VPC to create for SAP HANA deployment",
      "Type": "String",
      "Default": "'+$vpc_cidr+'"
    },
    HANAInstallMedia: {
      "Description": "Full path to Amazon S3 location of SAP HANA software files (e.g.,
      s3://myhanabucket/sap-hana-sps11/).",
      "Type:" "String",
      Default: "'+$hana_install_media+'"
    },
  },
  "Mappings": {},
  "Resources": {
    "VPC" : {
        "Type" : "AWS::EC2::VPC",
        "Properties" : {
          "CidrBlock" : '+$vpc_cidr+',
          "Tags" : [ {"Key" : "Application", "Value" :  "SAP HANA" } ]
        }
      }
  },
  "Outputs": {
  }
}')
end