name 'Azure Test CAT'
rs_ca_ver 20161221
short_description "Test CAT"
import "sys_log"
import "plugins/rs_azure_compute"

parameter "subscription_id" do
  like $rs_azure_compute.subscription_id
  default "8beb7791-9302-4ae4-97b4-afd482aadc59"
end

operation "launch" do
  definition "launch"
end

define launch() return @instances do
  call rs_azure_compute.start_debugging()
  sub on_error: rs_azure_compute.stop_debugging() do
    $instances = rs_azure_compute.virtualmachine.list_all()
    foreach $instance in $instances[0]["value"] do
      $vmname = $instance["name"]
      $uid = $instance["id"]
      $resource_group = split($uid, "/")[4]
      @instance = rs_azure_compute.virtualmachine.show(resource_group: $resource_group, virtualMachineName: $vmname)
      $status = @instance.instance_view()
      foreach $state in $status[0]["statuses"] do
        if $state["code"] =~ "PowerState"
          call sys_log.detail($instance["name"] + " status == " + $state["displayStatus"])
        end
      end
    end
  end
  call rs_azure_compute.stop_debugging()
end
