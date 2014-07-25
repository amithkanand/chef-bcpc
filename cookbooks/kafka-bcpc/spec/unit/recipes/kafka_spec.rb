require 'spec_helper'

describe "kafka-bcpc::kafka" do
  let(:chef_run) {ChefSpec::Runner.new.converge(described_recipe) }

  it 'includes kafka::_configure' do
    expect(chef_run).to include_recipe('kafka::_configure')
  end
  
  it 'runs ruby block kafkaup to check kafka status' do
    expect(chef_run).to run_ruby_block('kafkaup')
  end 

end
