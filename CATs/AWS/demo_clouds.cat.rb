name 'Package: Supported Demo Regions'
rs_ca_ver 20161221
short_description "![Network](https://media.flexera.com/images/logo-flexera-rightscale-v2-600.png)\n
A resource file for the CATs for Flexera's MCIs"

package "demo_clouds"

### Mappings ###
mapping "map_cloud" do {
  "US-Ohio" => {
    "cloud_href" => "/api/clouds/11",
    "cloud" => "AWS US-Ohio",
    "datacenter" => "us-east-2a",
    "instance_type" => "t3.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "us-east-2.compute.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  },
  "US-Oregon" => {
    "cloud_href" => "/api/clouds/6",
    "cloud" => "EC2 us-west-2",
    "datacenter" => "us-west-2a",
    "instance_type" => "t3.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "us-west-2.compute.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  },
  "EU-Frankfurt" => {
    "cloud_href" => "/api/clouds/9",
    "cloud" => "EC2 eu-central-1",
    "datacenter" => "eu-central-1a",
    "instance_type" => "t3.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "eu-central-1.compute.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  },
  "EU-Ireland" => {
    "cloud_href" => "/api/clouds/2",
    "cloud" => "EC2 eu-west-1",
    "datacenter" => "eu-west-1a",
    "instance_type" => "t3.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "eu-west-1.compute.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  },
  "AP-Sydney" => {
    "cloud_href" => "/api/clouds/8",
    "cloud" => "EC2 ap-southeast-2",
    "datacenter" => "ap-southeast-2a",
    "instance_type" => "t2.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "ap-southeast-2.compute.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  },
  "US-West" => {
    "cloud_href" => "/api/clouds/3",
    "cloud" => "EC2 us-west-1",
    "datacenter" => "us-west-1b",
    "instance_type" => "t3.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "us-west-1.compute.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  },
  "US-East" => {
    "cloud_href" => "/api/clouds/1",
    "cloud" => "EC2 us-east-1",
    "datacenter" => "us-east-1a",
    "instance_type" => "t3.xlarge",
    "tag_prefix" => "ec2",
    "domain-name" => "ec2.internal",
    "domain-name-servers" => "AmazonProvidedDNS"
  }
}
end
