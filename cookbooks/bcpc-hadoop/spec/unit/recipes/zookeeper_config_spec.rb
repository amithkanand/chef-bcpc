require 'spec_helper'

describe 'bcpc-hadoop::zookeeper_config' do

  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

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
end
