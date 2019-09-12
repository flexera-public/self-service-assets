name 'Package: Flexera LAN Map'
rs_ca_ver 20161221
short_description "![Network](https://media.flexera.com/images/logo-flexera-rightscale-v2-600.png)\n
A resource file for the CATs for Flexera's MCIs"

package "flex_lan"

### Mappings ###
mapping "map_flexlan" do {
    "Itasca" => {
      "cidr_ips" => "12.36.71.128/25",
   },
   "Oakland Office"=> {
      "cidr_ips" => "4.79.42.192/27",
   },
   "Maidenhead"=> {
     "cidr_ips" => "193.240.111.160/27",
   },
   "Melbourne"=> {
     "cidr_ips" => "123.29.30.96/27",
   },
   "Belfast"=> {
     "cidr_ips" => "62.200.74.32/27",
   },
   "Bangalore"=> {
     "cidr_ips" => "223.3.69.64/27",
   },
   "Oakland Digital Reality" => {
     "cidr_ips" => "4.78.241.224/27",
   },
   "Cheshire_1" => {
     "cidr_ips" => "193.240.73.160/27",
   },
   "Cheshire_2" => {
     "cidr_ips" => "195.212.143.0/27",
   }
  }
end
