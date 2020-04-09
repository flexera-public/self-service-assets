name "SAP HANA CFT Deployment CAT"
rs_ca_ver 20161221
short_description  "SAP HANA CFT Deployment CAT"
long_description "This CAT deploys SAP HANA on AWS using the AWS Cloud Formation template"

import "plugins/rs_aws_cft"

resource "stack", type: "rs_aws_cft.stack" do
    stack_name join(["emr-", last(split(@@deployment.href, "/"))])
    capabilities "CAPABILITY_IAM"
    template_body ""
    description "SAP HANA"
end

operation "launch" do
    description "Launch the application"
    definition "launch_handler"
end

define launch_handler(@stack,) return $cft_template,@stack do
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
    $app_arr = [{"Name":"SAP_HANA"}]
    foreach $app in split($applications,',') do
     $app_arr << { "Name": $app }
    end
    $app_json = to_json($app_arr)
  
    $cft_template = to_s('{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "Deploy AWS infrastructure and SAP HANA on AWS",
    "Parameters": {
    },
    "Mappings": {},
    "Resources": {
    },
    "Outputs": {
    }
}')
end