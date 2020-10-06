require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs mysql python packages by default' do
      expect(chef_run).to upgrade_package 'MySQL-python'
    end

    it 'installs the common packages' do
      expect(chef_run).to upgrade_package %w(openstack-ceilometer-common mod_wsgi)
    end
  end
end
