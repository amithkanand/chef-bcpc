require 'spec_helper'

describe 'bcpc-hadoop::zookeeper_server' do

  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'includes zookeeper_config' do
    expect(chef_run).to include_recipe('bcpc-hadoop::zookeeper_config')
  end
  
  it 'creates a directory for storing Zookeeper config files' do
    expect(chef_run).to create_directory('/etc/zookeeper/conf._default').with({
      recursive: true,
      owner: chef_run.node[:bcpc][:zookeeper][:owner],
      group: chef_run.node[:bcpc][:zookeeper][:group],
      mode: 00755})
  end
  
  it 'updates alternatives for zookeeper config files' do
    expect(chef_run).to run_bash('update-zookeeper-conf-alternatives')
  end
 
  it 'creates configuration files for zookeeper' do
  %w{zoo.cfg
     log4j.properties
     configuration.xsl
  }.each do |t|
      templatename = "/etc/zookeeper/conf/#{t}"
      templatesource = "zk_#{t}.erb"
      expect(chef_run).to create_template(templatename).with({source: templatesource, mode: 0644})
    end
  end

  it 'includes dpkg_autostart' do
    expect(chef_run).to include_recipe('dpkg_autostart')
  end
  
  it 'installs/upgrades zookeeper-server package' do
 
    expect(chef_run).to upgrade_package('zookeeper-server')
    
    resource = chef_run.package('zookeeper-server')
    expect(resource).to notify('template[/var/chef/cache/zkServer.sh]').to(:create).immediately
 
    resource = chef_run.template('/var/chef/cache/zkServer.sh')
    expect(resource).to notify('ruby_block[Compare_zookeeper_server_start_shell_script]').to(:create).immediately
  end

  it 'does not create a script file on its own' do
    resource = chef_run.template('/var/chef/cache/zkServer.sh')
    expect(resource).to do_nothing
  end
  
  it 'does not runs a ruby block on its own' do
    resource = chef_run.ruby_block('Compare_zookeeper_server_start_shell_script')
    expect(resource).to do_nothing
  end
  
  it 'creates a daemon script for zookeeper server' do
    expect(chef_run).to create_template('/etc/init.d/zookeeper-server').with({
      source: 'hdp_zookeeper-server.start.erb', 
      mode: 0655})
  end

  it 'creates a directory to store zookeeper data' do
    expect(chef_run).to create_directory(chef_run.node[:bcpc][:zookeeper][:data_dir]).with({
      recursive: true, 
      owner: chef_run.node[:bcpc][:zookeeper][:owner],
      group: chef_run.node[:bcpc][:zookeeper][:group],
      mode: 0755 })
  end

  it 'creates a file to store environment variables for zookeeper' do
    expect(chef_run).to create_template('/etc/default/zookeeper-server').with({
      source: 'hdp_zookeeper-server.default.erb', 
      mode: 0644})
  end

  it 'creates a shell script file for zookeeper server' do
    expect(chef_run).to create_template('/usr/lib/zookeeper/bin/zkServer.sh').with({source: 'hdp_zkServer.sh.erb'})
  end

  it 'initializes zookeeper server' do
    expect(chef_run).to run_bash('init-zookeeper').with({
      user: chef_run.node[:bcpc][:zookeeper][:owner], 
      group: chef_run.node[:bcpc][:zookeeper][:group],
      umask: 0644,
      })
  end
  
  it 'starts zookeeper server' do
    expect(chef_run).to enable_service('zookeeper-server')
    expect(chef_run).to start_service('zookeeper-server')
    resource = chef_run.service('zookeeper-server')
    expect(resource).to subscribe_to('template[/etc/zookeeper/conf/zoo.cfg]').on(:restart).delayed
  end 
end
