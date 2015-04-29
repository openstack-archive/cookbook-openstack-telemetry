# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::agent-compute' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the agent-compute package' do
      expect(chef_run).to upgrade_package 'ceilometer-agent-compute'
    end

    it 'enables and starts the ceilometer-agent-compute service' do
      expect(chef_run).to enable_service('ceilometer-agent-compute')
      expect(chef_run).to start_service('ceilometer-agent-compute')
    end

    describe 'ceilometer-agent-compute' do
      it 'subscribes to its config file' do
        expect(chef_run.service('ceilometer-agent-compute')).to subscribe_to('template[/etc/ceilometer/ceilometer.conf]').delayed
      end
    end
  end
end
