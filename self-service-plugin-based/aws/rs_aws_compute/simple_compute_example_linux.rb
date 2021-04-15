name 'AWS Simple Linux Instance'
rs_ca_ver 20161221
short_description "AWS EC2 Linux Instance"
import "sys_log"
import "plugin/rs_aws_compute"

parameter "param_region" do
  like $rs_aws_compute.param_region
end

parameter "param_ami_id" do
  label "AMI Id"
  type "string"
end

parameter "param_instance_type" do
  label "Instance Type"
  type "string"
end

parameter "param_min_count" do
  label "Minimum Count"
  type "number"
  default 1
end

parameter "param_max_count" do
  label "Maximum Count"
  type "string"
  default 1
end

parameter "param_key_name" do
  label "Key Name"
  type "string"
end

parameter "param_subnet_id" do
  label "Subnet Id"
  type "string"
end

output "output_instance_id" do
  label "InstanceId"
  default_value $instance_id
end

output "output_dns_name" do
  label "DNS Id"
  default_value $instance_dns_name
end

output "output_ami_id" do
  label "AMI Id"
end

resource "instance", type: "aws_compute.instances" do
  image_id $param_ami
  instance_type $param_instance_type
  subnet_id $param_subnet_id
  key_name $param_key_name
  min_count "1"
  max_count "1"
  placement_availability_zone $param_az
  placement_tenancy "default"
  tag_specification_1_resource_type "instance"
  tag_specification_1_tag_1_key "Name"
  tag_specification_1_tag_1_value @@deployment.name
end

operation "launch" do
  definition "generated_launch"
  output_mappings do {
    $output_instance_id => $instance_id,
    $output_dns_name => $instance_dns_name
  } end
end

operation "terminate" do
  definition "generated_terminate"
end


define handle_retries($attempts) do
  if $attempts <= 10
    sleep(60)
    $_error_behavior = "retry"
  else
    $_error_behavior = "skip"
  end
end

define generated_launch($param_region,@my_vpc,@my_vpc_endpoint,@my_rs_vpc,@my_rs_vpc_endpoint,@my_nat_ip,@my_nat_gateway,@my_subnet,@my_igw,@my_rs_vpc_tag,@my_volume,@my_vpc_tag,@my_sg,@my_rt_igw,@server1) return @my_vpc,@my_vpc_endpoint,@my_rs_vpc,@my_rs_vpc_endpoint,@my_nat_ip,@my_nat_gateway,@my_subnet,@my_igw,@my_rs_vpc_tag,@my_volume,@my_sg,@my_rt_igw,@instance,$instance_dns_name,$instance_id,@server1 do
  call rs_aws_compute.start_debugging()
  sub on_error: rs_aws_compute.stop_debugging() do
  end
end

define generated_terminate(@server1,@my_vpc,@my_vpc_endpoint,@my_rs_vpc,@my_rs_vpc_endpoint,@my_nat_gateway,@my_nat_ip,@my_igw,@my_subnet,@my_rt_igw) do

end


aws-marketplace/ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20191113-d83d0782-cb94-46d7-8993-f4ce15d1a484-ami-02fb1c72d81ced91a.4
734555027572/ultraserve-centos-7.4-ami-application-hvm-2018.03.2-60-x86_64-gp2
amazon/suse-sles-12-sp5-v20200226-hvm-ssd-x86_64
