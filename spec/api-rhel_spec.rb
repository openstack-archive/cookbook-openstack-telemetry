# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the api package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer-api'
    end
  end
end
