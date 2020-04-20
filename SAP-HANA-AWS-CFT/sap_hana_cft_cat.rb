name "SAP HANA CFT Deployment CAT"
rs_ca_ver 20161221
short_description  "SAP HANA CFT Deployment CAT"
long_description "This CAT deploys SAP HANA on AWS using the AWS Cloud Formation template"

import "plugins/rs_aws_cft"

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

parameter "volume_type_hana_data" do
  type "string"
  label "Data Volume Type"
  default "gp2"
  allowed_values "gp2","io1"
  constraint_description "EBS volume type for SAP HANA Data: General Purpose SSD (gp2) or
  Provisioned IOPS SSD (io1)."
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

define launch_handler(@stack) return $cft_template,@stack do
  call generate_cloudformation_template() retrieve $cft_template
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
define generate_cloudformation_template() return $cft_template do
    $cft_template = to_s('{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "Deploy AWS infrastructure and SAP HANA on AWS",
    "Resources": {
        "VPC": {
            "Type": "AWS::EC2::VPC",
            "Properties": {
                "CidrBlock": "10.0.0.0/16",
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackId"
                        }
                    }
                ]
            }
        },
        "Subnet": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": {
                    "Ref": "VPC"
                },
                "CidrBlock": "10.0.2.0/24",
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackId"
                        }
                    }
                ]
            }
        },
        "InternetGateway": {
            "Type": "AWS::EC2::InternetGateway",
            "Properties": {
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackId"
                        }
                    }
                ]
            }
        },
        "AttachGateway": {
            "Type": "AWS::EC2::VPCGatewayAttachment",
            "Properties": {
                "VpcId": {
                    "Ref": "VPC"
                },
                "InternetGatewayId": {
                    "Ref": "InternetGateway"
                }
            }
        },
        "RouteTable": {
            "Type": "AWS::EC2::RouteTable",
            "Properties": {
                "VpcId": {
                    "Ref": "VPC"
                },
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackId"
                        }
                    }
                ]
            }
        },
        "Route": {
            "Type": "AWS::EC2::Route",
            "DependsOn": "AttachGateway",
            "Properties": {
                "RouteTableId": {
                    "Ref": "RouteTable"
                },
                "DestinationCidrBlock": "0.0.0.0/0",
                "GatewayId": {
                    "Ref": "InternetGateway"
                }
            }
        },
        "SubnetRouteTableAssociation": {
            "Type": "AWS::EC2::SubnetRouteTableAssociation",
            "Properties": {
                "SubnetId": {
                    "Ref": "Subnet"
                },
                "RouteTableId": {
                    "Ref": "RouteTable"
                }
            }
        },
        "NetworkAcl": {
            "Type": "AWS::EC2::NetworkAcl",
            "Properties": {
                "VpcId": {
                    "Ref": "VPC"
                },
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackId"
                        }
                    }
                ]
            }
        },
        "InboundHTTPNetworkAclEntry": {
            "Type": "AWS::EC2::NetworkAclEntry",
            "Properties": {
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                },
                "RuleNumber": "100",
                "Protocol": "6",
                "RuleAction": "allow",
                "Egress": "false",
                "CidrBlock": "0.0.0.0/0",
                "PortRange": {
                    "From": "80",
                    "To": "80"
                }
            }
        },
        "InboundSSHNetworkAclEntry": {
            "Type": "AWS::EC2::NetworkAclEntry",
            "Properties": {
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                },
                "RuleNumber": "101",
                "Protocol": "6",
                "RuleAction": "allow",
                "Egress": "false",
                "CidrBlock": "0.0.0.0/0",
                "PortRange": {
                    "From": "22",
                    "To": "22"
                }
            }
        },
        "InboundResponsePortsNetworkAclEntry": {
            "Type": "AWS::EC2::NetworkAclEntry",
            "Properties": {
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                },
                "RuleNumber": "102",
                "Protocol": "6",
                "RuleAction": "allow",
                "Egress": "false",
                "CidrBlock": "0.0.0.0/0",
                "PortRange": {
                    "From": "1024",
                    "To": "65535"
                }
            }
        },
        "OutBoundHTTPNetworkAclEntry": {
            "Type": "AWS::EC2::NetworkAclEntry",
            "Properties": {
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                },
                "RuleNumber": "100",
                "Protocol": "6",
                "RuleAction": "allow",
                "Egress": "true",
                "CidrBlock": "0.0.0.0/0",
                "PortRange": {
                    "From": "80",
                    "To": "80"
                }
            }
        },
        "OutBoundHTTPSNetworkAclEntry": {
            "Type": "AWS::EC2::NetworkAclEntry",
            "Properties": {
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                },
                "RuleNumber": "101",
                "Protocol": "6",
                "RuleAction": "allow",
                "Egress": "true",
                "CidrBlock": "0.0.0.0/0",
                "PortRange": {
                    "From": "443",
                    "To": "443"
                }
            }
        },
        "OutBoundResponsePortsNetworkAclEntry": {
            "Type": "AWS::EC2::NetworkAclEntry",
            "Properties": {
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                },
                "RuleNumber": "102",
                "Protocol": "6",
                "RuleAction": "allow",
                "Egress": "true",
                "CidrBlock": "0.0.0.0/0",
                "PortRange": {
                    "From": "1024",
                    "To": "65535"
                }
            }
        },
        "SubnetNetworkAclAssociation": {
            "Type": "AWS::EC2::SubnetNetworkAclAssociation",
            "Properties": {
                "SubnetId": {
                    "Ref": "Subnet"
                },
                "NetworkAclId": {
                    "Ref": "NetworkAcl"
                }
            }
        },
        "HANASecurityGroup": {
            "Type": "AWS::EC2::SecurityGroup",
            "Properties": {
                "GroupDescription": "Enable external access to the HANA Master and allow communication from slave instances",
                "VpcId": {
                    "Ref": "VPC"
                }
            }
        },
        "HANASubnet": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": {
                    "Ref": "VPC"
                },
                "CidrBlock": "10.0.1.0/24",
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": "HANA"
                    },
                    {
                        "Key": "Name",
                        "Value": "Private Subnet - HANA"
                    },
                    {
                        "Key": "Network",
                        "Value": "Private"
                    }
                ]
            }
        },
        "HANAMasterInterface": {
            "Type": "AWS::EC2::NetworkInterface",
            "Properties": {
                "Description": "Network Interface for HANA Master",
                "SubnetId": {
                    "Ref": "HANASubnet"
                },
                "GroupSet": [
                    {
                        "Ref": "HANASecurityGroup"
                    }
                ],
                "SourceDestCheck": "true",
                "Tags": [
                    {
                        "Key": "Network",
                        "Value": "Private"
                    }
                ]
            }
        },
        "HANAMasterInstance": {
            "Type": "AWS::EC2::Instance",
            "Metadata": {
                "HostRole": "Master",
            },
            "Properties": {
                "NetworkInterfaces": [
                    {
                        "NetworkInterfaceId": {
                            "Ref": "HANAMasterInterface"
                        },
                        "DeviceIndex": "0"
                    }
                ],
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sda1",
                        "Ebs": {
                            "VolumeSize": "50",
                            "VolumeType": "gp2"
                        }
                    }
                ],
                "ImageId": "ami-0787571b4033204ad",
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "SAP HANA Master"
                    }
                ],
                "InstanceType": "r5.2xlarge",
            }
        },
        "HANAWorker1Interface": {
            "Type": "AWS::EC2::NetworkInterface",
            "Properties": {
                "SubnetId": {
                    "Ref": "HANASubnet"
                },
                "Description": "Interface for HANA Worker 1",
                "GroupSet": [
                    {
                        "Ref": "HANASubnet"
                    }
                ],
                "SourceDestCheck": "true",
                "Tags": [
                    {
                        "Key": "Network",
                        "Value": "Private"
                    }
                ]
            }
        },
        "HANAWorkerInstance1": {
            "Type": "AWS::EC2::Instance",
            "Metadata": {
                "HostRole": "Worker"
            },
            "Properties": {
                "NetworkInterfaces": [
                    {
                        "NetworkInterfaceId": {
                            "Ref": "HANAWorker1Interface"
                        },
                        "DeviceIndex": "0"
                    }
                ],
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sda1",
                        "Ebs": {
                            "VolumeSize": "50",
                            "VolumeType": "gp2"
                        }
                    }
                ],
                "ImageId": "ami-0787571b4033204ad",
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "SAP HANA Worker 1"
                    }
                ],
                "InstanceType": "r5.2xlarge"
            }
        }
    }
}')
end