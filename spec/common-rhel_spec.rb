# encoding: UTF-8

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

    it 'installs the common package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer-common'
      expect(chef_run).to upgrade_package 'mod_wsgi'
    end
  end
end
