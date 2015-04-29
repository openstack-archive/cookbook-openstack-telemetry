# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::agent-central' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the agent-central package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer-central'
    end

    it 'starts the agent-central service' do
      expect(chef_run).to start_service 'openstack-ceilometer-central'
    end
  end
end
