
include_recipe 'bcpc-hadoop::zookeeper_config'
include_recipe 'dpkg_autostart'

dpkg_autostart "zookeeper-server" do
  allow false
end

package  "zookeeper-server" do
  action :upgrade
  notifies :create, "template[#{Chef::Config[:file_cache_path]}/zkServer.sh]", :immediately
end

template "#{Chef::Config[:file_cache_path]}/zkServer.sh" do
  source "hdp_zkServer.sh.orig.erb"
  mode 0644
  action :nothing
  notifies :create, "ruby_block[Compare_zookeeper_server_start_shell_script]", :immediately
end

ruby_block "Compare_zookeeper_server_start_shell_script" do
  block do
    require "digest"
    orig_checksum=Digest::MD5.hexdigest(File.read("#{Chef::Config[:file_cache_path]}/zkServer.sh"))
    new_checksum=Digest::MD5.hexdigest(File.read("/usr/lib/zookeeper/bin/zkServer.sh"))
    if orig_checksum != new_checksum
      Chef::Application.fatal!("zookeeper-server:New version of zkServer.sh need to be created and used")
    end
  end
  action :nothing
end

template "/etc/init.d/zookeeper-server" do
  source "hdp_zookeeper-server.start.erb"
  mode 0655
end

directory node[:bcpc][:zookeeper][:data_dir] do
  recursive true
  owner node[:bcpc][:zookeeper][:owner]
  group node[:bcpc][:zookeeper][:group]
  mode 0755
end

template "/etc/default/zookeeper-server" do
  source "hdp_zookeeper-server.default.erb"
  mode 0644
  variables(:zk_jmx_port => node[:bcpc][:zookeeper][:jmx_port])
end

template "/usr/lib/zookeeper/bin/zkServer.sh" do
  source "hdp_zkServer.sh.erb"
end

bash "init-zookeeper" do
  code "service zookeeper-server init --myid=#{node[:bcpc][:node_number]}"
  creates "#{node[:bcpc][:zookeeper][:data_dir]}/myid"
  user node[:bcpc][:zookeeper][:owner]
  group node[:bcpc][:zookeeper][:group]
  umask 0644
end

service "zookeeper-server" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/zookeeper/conf/zoo.cfg]", :delayed
end
