# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs mysql python packages by default' do
      expect(chef_run).to upgrade_package 'python-mysql'
    end

    it 'installs postgresql python packages if explicitly told' do
      node.set['openstack']['db']['telemetry']['service_type'] = 'postgresql'
      expect(chef_run).to upgrade_package 'python-psycopg2'
    end

    it 'installs the common package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer'
    end
  end
end
