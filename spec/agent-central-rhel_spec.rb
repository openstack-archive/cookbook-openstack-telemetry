require_relative 'spec_helper'

describe 'openstack-telemetry::agent-central' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

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
end
