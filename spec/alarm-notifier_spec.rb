# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::alarm-notifier' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the alarm-notifier package' do
      expect(chef_run).to install_package 'ceilometer-alarm-notifier'
    end

    it 'starts alarm-notifier service' do
      expect(chef_run).to start_service('ceilometer-alarm-notifier')
    end
  end
end
