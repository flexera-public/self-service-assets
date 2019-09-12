name 'Package: Flexera VPN Map'
rs_ca_ver 20161221
short_description "![Network](https://media.flexera.com/images/logo-flexera-rightscale-v2-600.png)\n
A resource file for the CATs for Flexera's MCIs"

package "flex_vpn"

### Mappings ###

mapping "map_flexvpn" do {
    "Itasca" => {
      "cidr_ips" => "4.71.181.0/25",
   },
   "Oakland"=> {
      "cidr_ips" => "12.3.78.192/27",
   },
   "Maidenhead"=> {
     "cidr_ips" => "195.212.143.100/27",
   },
   "Melbourne"=> {
     "cidr_ips" => "122.248.150.36/27",
   },
   "Belfast"=> {
     "cidr_ips" => "193.240.83.228/27",
   },
   "Bangalore"=> {
     "cidr_ips" => "14.143.29.101/27",
   }
  }
end
