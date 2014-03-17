# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the common package' do
      expect(chef_run).to install_package 'openstack-ceilometer'
    end
  end
end
