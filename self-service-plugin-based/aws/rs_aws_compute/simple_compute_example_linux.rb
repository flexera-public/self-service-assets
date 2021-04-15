name 'AWS Simple Linux Instance'
rs_ca_ver 20161221
short_description "AWS EC2 Linux Instance"
import "sys_log"
import "plugin/rs_aws_compute"

parameter "param_region" do
  like $aws_compute.param_region
end

parameter "param_ami" do
  label "AMI Id"
  type "string"
end

parameter "param_instance_type" do
  label "Instance Type"
  type "string"
end

parameter "param_subnet_id" do
  label "Subnet Id"
  type "string"
end

parameter "param_key_name" do
  label "Key Name"
  type "string"
end

parameter "param_az" do
  label "Availability Zone"
  type "string"
end

operation "launch" do
  definition "defn_launch"
end

operation "stop" do
  definition "defn_stop"
end

operation "start" do
  definition "defn_start"
end

operation "terminate" do
  definition "defn_terminate"
end

operation "create_and_attach_volume" do
  definition "create_and_attach_volume"
end

define defn_launch($param_region, @instance) return @instance do
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    provision(@instance)
  end
  call aws_compute.stop_debugging()
end

define defn_stop(@instance) return @instance do
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    @instance.stop(instance_id: @instance.id)
  end
  call aws_compute.stop_debugging()
end

define defn_start(@instance) return @instance do
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    @instance.start(instance_id: @instance.id)
  end
  call aws_compute.stop_debugging()
end

define defn_terminate(@instance) do
  delete(@instance)
end

define create_and_attach_volume(@instance,$param_volume_size, $param_region, $param_az) do
  call aws_compute.start_debugging()
  @volume = aws_compute.volume.empty()
  sub on_error: aws_compute.stop_debugging() do
    @volume = aws_compute.volume.create(
      availability_zone: $param_az,
      size: $param_volume_size,
      volume_type: "gp2"
    )
  end
  $state = @volume.state
  call aws_compute.stop_debugging()
  while $state != "available" do
    sleep(10)
    call sys_log.detail(join(["state: ", $state]))
    call aws_compute.start_debugging()
    $state = @volume.state
    call aws_compute.stop_debugging()
  end
  call aws_compute.start_debugging()
  sub on_error: aws_compute.stop_debugging() do
    @instance.attach_volume(instance_id: @instance.id, volume_id: @volume.id, device: "/dev/sdb")
  end
  call aws_compute.stop_debugging()
end
