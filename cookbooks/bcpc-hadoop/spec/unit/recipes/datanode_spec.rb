require 'spec_helper'

describe 'bcpc-hadoop::datanode' do

  let(:chef_run) do 
    ChefSpec::Runner.new do |node|
      node.set[:bcpc][:hadoop][:mounts] = ['sdb','sdc']
#      env = Chef::Environment.new
#      env.name 'Test-Laptop'
#      allow(node).to receive(:chef_environment).and_return(env.name)
#      allow(Chef::Environment).to receive(:load).and_return(env)
    end.converge(described_recipe)
  end

  it 'installs packages for setting up datanode' do
    %w{hadoop-yarn-nodemanager
      hadoop-hdfs-datanode
      hadoop-mapreduce
      hadoop-client
      sqoop
      lzop
      hadoop-lzo}.each do |pkg|
        expect(chef_run).to upgrade_package(pkg)
    end
  end

  it 'creates container-executor configuration file' do
    expect(chef_run).to create_template('/etc/hadoop/conf/container-executor.cfg').with({
      source: 'hdp_container-executor.cfg.erb',
      owner: 'root',
      group: 'yarn',
      mode: '0400'})

      resource = chef_run.template('/etc/hadoop/conf/container-executor.cfg')
      expect(resource).to notify('bash[verify-container-executor]').to(:run).immediately
  end

  it 'does not verify container executor on its own' do
    resource = chef_run.bash('verify-container-executor')
    expect(resource).to do_nothing
  end

  it 'creates an environment file for sqoop' do
    expect(chef_run).to create_template('/etc/sqoop/conf/sqoop-env.sh').with({
      source: 'sq_sqoop-env.sh.erb',
      mode: '0444'})
  end

  it 'creates a user for hive catalog' do
    expect(chef_run).to create_user('hcat').with ({
      username: 'hcat',
      system: true,
      shell: '/bin/bash',
      home: '/usr/lib/hcatalog'})
  end

  it 'installs packages for hive' do
    %w{hive hcatalog libmysql-java}.each do |pkg|
      expect(chef_run).to upgrade_package(pkg)
    end
  end

  it 'creates a link to mysql jar' do
    link = chef_run.link('/usr/lib/hive/lib/mysql.jar')
    expect(link).to link_to('/usr/share/java/mysql.jar')
  end

  it 'create directories for HDFS storage' do
    chef_run.node[:bcpc][:hadoop][:mounts].each do |i|

      dfsdir = "/disk/#{i}/dfs" 
      expect(chef_run).to create_directory(dfsdir).with({
        owner: 'hdfs',
        group: 'hdfs',
        mode: 0700})

      dndir = "/disk/#{i}/dfs/dn"
      expect(chef_run).to create_directory(dndir).with({
        owner: 'hdfs',
        group: 'hdfs',
        mode: 0700})
    end
  end

  it 'create directories for YARN log storage' do
    chef_run.node[:bcpc][:hadoop][:mounts].each do |i|
      yarndir = "/disk/#{i}/yarn/" 
      expect(chef_run).to create_directory(yarndir).with({
        owner: 'yarn',
        group: 'yarn',
        mode: 0755})

      %w{mapred-local local logs}.each do |d|
        yarnlogdir = "#{yarndir}#{d}"
        expect(chef_run).to create_directory(yarnlogdir).with({
        owner: 'yarn',
        group: 'hadoop',
        mode: 0755})
      end
    end
  end

  it 'enables and starts services for datanode' do
    %w{hadoop-yarn-nodemanager hadoop-hdfs-datanode}.each do |svc|
      expect(chef_run).to enable_service(svc)
      expect(chef_run).to start_service(svc)
    end
  end
end
