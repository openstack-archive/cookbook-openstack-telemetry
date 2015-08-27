# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'creates the /var/cache/ceilometer directory' do
      expect(chef_run).to create_directory('/var/cache/ceilometer').with(
        user: 'ceilometer',
        group: 'ceilometer',
        mode: 0700
      )
    end

    it 'installs the api package' do
      expect(chef_run).to upgrade_package('openstack-ceilometer-api')
    end

    it 'starts api service' do
      expect(chef_run).to start_service('openstack-ceilometer-api')
    end
  end
end
