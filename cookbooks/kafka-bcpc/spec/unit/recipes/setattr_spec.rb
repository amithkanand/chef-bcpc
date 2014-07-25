require 'spec_helper'

describe 'kafka-bcpc::setattr' do
  let(:chef_run) { ChefSpec::Runner.new }
  it 'overrides values for kafka and zookeeper attributes' do
    stub_search("node", "role:BCPC-Kafka-Head-Zookeeper AND chef_environment:_default").and_return([])
    stub_search("node", "roles:BCPC-Kafka-Head-Zookeeper AND chef_environment:_default").and_return([])
    chef_run.converge 'kafka-bcpc::setattr'
    expect(chef_run.node.kafka.automatic_start).to eq true
    expect(chef_run.node.kafka.automatic_restart).to eq true
    expect(chef_run.node.java.jdk_version).to eq '7'
    expect(chef_run.node.kafka.advertised_port).to eq 9092
    expect(chef_run.node.kafka.host_name).to eq chef_run.node.fqdn
    expect(chef_run.node.kafka.advertised_host_name).to eq chef_run.node.fqdn
    expect(chef_run.node.kafka.jmx_port).to eq chef_run.node.bcpc.hadoop.kafka.jmx.port
 end
end


