bash "add-bootstrap-to-chef-server" do
 cwd "/home/vagrant/chef-bcpc"
 user "root"
 code <<-EOH
   chown $(whoami):root .chef/#{node[:hostname]}.pem;
   chmod 550 .chef/#{node[:hostname]}.pem;
   chown -R vagrant:vagrant .chef;
 EOH
end

bash "convert-bootstrap-to-admin-node" do
  cwd "/home/vagrant/chef-bcpc"
  user "root" 
  code "./convert_bootstrap_admin.sh; knife node run_list add #{node[:hostname]} 'role[BCPC-Bootstrap]' -c .chef/knife.rb"
end
