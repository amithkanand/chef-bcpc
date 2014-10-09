

bash "cleanup-bootstrap-from-chef-server" do
 cwd "/home/vagrant/chef-bcpc"
 user "root"
 code <<-EOH
   knife node delete #{node[:hostname]} -y -k /etc/chef-server/admin.pem -u admin;
   knife client delete #{node[:hostname]} -y -k /etc/chef-server/admin.pem -u admin;
   rm -f .chef/*.pem;
 EOH
 ignore_failure true
end


