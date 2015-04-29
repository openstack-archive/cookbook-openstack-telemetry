# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::agent-compute' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the agent-compute package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer-agent-compute'
    end

    it 'starts the agent-compute service' do
      expect(chef_run).to start_service 'openstack-ceilometer-agent-compute'
    end
  end
end
