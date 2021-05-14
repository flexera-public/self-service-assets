terraform {
  backend "remote" {
    organization = "Flexera-SE"

    workspaces {
      name = "Flexera-SE-API"
    }
  }
}

provider "aws" {}

variable "instances_number" {
  default = 1
}

variable "instance_type" {
  default = "t3.medium"
}

variable "hostname" {
  default = "example-with-ebs"
}

variable "tag_business_unit" {}

variable "tag_env" {}

##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  name        = "tf-example"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

resource "aws_instance" "this_ec2_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
  tags = {
    "Name" = var.hostname
    "BusinessUnit" = var.tag_business_unit
    "env" = var.tag_env
  }
}

resource "aws_volume_attachment" "this_ec2" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.id
  instance_id = aws_instance.this_ec2_instance.id
}

resource "aws_ebs_volume" "this" {
  availability_zone = aws_instance.this_ec2_instance.availability_zone
  size              = 10
  type       = "gp3"
  tags = {
    "Name"         = "${var.hostname}_ec2_volume"
    "BusinessUnit" = var.tag_business_unit
    "env"          = var.tag_env
  }
}
