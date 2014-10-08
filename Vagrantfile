# -*- mode: ruby -*-
# vi: set ft=ruby :

# This is a Vagrant to automatically provision a bootstrap node with a
# Chef server.
# See http://www.vagrantup.com/ for info on Vagrant.

require 'json'
$local_mirror = nil

base_dir = File.expand_path(File.dirname(File.realpath(__FILE__)))
json_file = Dir[File.join(base_dir,'*.json')]

if json_file.empty? 
  puts "No environment file found to parse. Please make sure at least one environment file exists."
  exit
end

if json_file.length > 1 
  puts "More than one environment file found."
  exit
end

file_name=File.basename(json_file.join(","))
chef_env = JSON.parse(File.read(json_file.join(",")))
bridge_if = chef_env["override_attributes"]["bcpc"]["bootstrap"]["pxe_interface"]
ip_address = chef_env["override_attributes"]["bcpc"]["bootstrap"]["server"]
env_name = chef_env["name"]
host_name = "bcpc-bootstrap"


puts "Base dir   : #{base_dir}"
puts "Json file  : #{json_file}"
puts "Interface  : #{bridge_if}"
puts "IP Address : #{ip_address}"
puts "Chef Env   : #{env_name}"
puts "hostname   : #{host_name}"
puts "File name  : #{file_name}"

Vagrant.configure("2") do |config|

  config.vm.define :bootstrap do |bootstrap|

    bootstrap.vm.hostname = host_name

    bootstrap.vm.network :private_network, ip: ip_address, netmask: "255.255.255.0", adapter_ip: "10.0.100.2", auto_config: false
    bootstrap.vm.network :private_network, ip: "172.16.100.3", netmask: "255.255.255.0", adapter_ip: "172.16.100.2"
    bootstrap.vm.network :private_network, ip: "192.168.100.3", netmask: "255.255.255.0", adapter_ip: "192.168.100.2"

    bootstrap.vm.synced_folder "../", "/chef-bcpc-host"

    # set up repositories
    if $local_mirror then
      bootstrap.vm.provision :shell, :inline => <<-EOH
        sed -i s/archive.ubuntu.com/#{$local_mirror}/g /etc/apt/sources.list
        sed -i s/security.ubuntu.com/#{$local_mirror}/g /etc/apt/sources.list
        sed -i s/^deb-src/\#deb-src/g /etc/apt/sources.list
      EOH
    end

    # Chef provisioning
    bootstrap.vm.provision "chef_solo" do |chef|
      chef.environments_path = [[:vm,""]]
      chef.environment = env_name
      chef.cookbooks_path = [[:vm,""]]
      chef.roles_path = [[:vm,""]]
      chef.add_recipe("bcpc::bootstrap_network")
      chef.log_level="debug"
      chef.verbose_logging=true
      chef.provisioning_path="/home/vagrant/chef-bcpc/"
    end

    # Reconfigure chef-server
    bootstrap.vm.provision :file, source: json_file.join(","), destination: "/home/vagrant/chef-bcpc/environment/#{file_name}"
    bootstrap.vm.provision :shell, :inline => "sudo chef-server-ctl reconfigure"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo knife node delete #{host_name}"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo knife client delete #{host_name}"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo rm -f .chef/*.pem"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo chef-client -E #{env_name} -c .chef/knife.rb"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo chown $(whoami):root .chef/$(hostname -f).pem"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo chmod 550 .chef/$(hostname -f).pem"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; sudo knife environment from file environments/#{file_name}"
    bootstrap.vm.provision :shell, :inline => "cd /home/vagrant/chef-bcpc; echo -e \"/\"admin\": false\ns/false/true\nw\nq\n\" | EDITOR=ed sudo -E knife client edit `hostname -f` -c .chef/knife.rb -k /etc/chef-server/admin.pem -u admin"
    bootstrap.vm.provision :shell, :inline => "sudo chef-client -c /home/vagrant/chef-bcpc/.chef/knife.rb"

  end


  config.vm.box = "precise64"
  config.vm.box_url = "precise-server-cloudimg-amd64-vagrant-disk1.box"

  memory = ( ENV["BOOTSTRAP_VM_MEM"] or "8192" )
  cpus = ( ENV["BOOTSTRAP_VM_CPUs"] or "4" )

  config.vm.provider :virtualbox do |vb|
     # Don't boot with headless mode
     vb.gui = false
     vb.name = host_name
     vb.customize ["modifyvm", :id, "--nictype2", "82543GC"]
     vb.customize ["modifyvm", :id, "--memory", memory]
     vb.customize ["modifyvm", :id, "--cpus", cpus]
     vb.customize ["modifyvm", :id, "--largepages", "on"]
     vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
     vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
     vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
     vb.customize ["modifyvm", :id, "--ioapic", "on"]
   end
end
