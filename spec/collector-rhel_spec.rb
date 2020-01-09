# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the collector package' do
      expect(chef_run).to upgrade_package('openstack-ceilometer-collector')
    end

    it 'starts collector service' do
      expect(chef_run).to start_service('openstack-ceilometer-collector')
    end
  end
end
