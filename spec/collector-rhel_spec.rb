# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'executes ceilometer dbsync' do
      node.set['openstack']['telemetry']['dbsync_timeout'] = 36000
      command = 'ceilometer-dbsync --config-file /etc/ceilometer/ceilometer.conf'
      expect(chef_run).to run_execute(command).with(
        timeout: 36000
      )
    end

    it 'installs the collector package' do
      expect(chef_run).to upgrade_package('openstack-ceilometer-collector')
    end

    it 'starts collector service' do
      expect(chef_run).to start_service('openstack-ceilometer-collector')
    end
  end
end
