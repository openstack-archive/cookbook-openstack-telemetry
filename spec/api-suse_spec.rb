# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the api package' do
      expect(chef_run).to upgrade_package('openstack-ceilometer-api')
    end

    it 'starts api service' do
      expect(chef_run).to start_service('openstack-ceilometer-api')
    end
  end
end
