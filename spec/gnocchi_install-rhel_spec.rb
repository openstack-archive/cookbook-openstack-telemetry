require_relative 'spec_helper'

describe 'openstack-telemetry::gnocchi_install' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'telemetry-stubs'

      it do
        expect(chef_run).to upgrade_package %w(openstack-gnocchi-api openstack-gnocchi-metricd)
      end

      it do
        expect(chef_run).to stop_service('openstack-gnocchi-api')
        expect(chef_run).to disable_service('openstack-gnocchi-api')
      end
    end
  end
end
