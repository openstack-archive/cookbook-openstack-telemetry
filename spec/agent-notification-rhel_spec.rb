require_relative 'spec_helper'

describe 'openstack-telemetry::agent-notification' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it do
      expect(chef_run).to upgrade_package %w(openstack-ceilometer-collector openstack-ceilometer-notification)
    end

    it 'starts the agent-notification service' do
      expect(chef_run).to start_service 'openstack-ceilometer-notification'
    end
  end
end
