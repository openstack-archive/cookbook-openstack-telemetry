# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::alarm-notifier' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the alarm-notifier package' do
      expect(chef_run).to upgrade_package 'ceilometer-alarm-notifier'
    end

    it 'starts and enables the alarm-notifier service' do
      expect(chef_run).to enable_service('ceilometer-alarm-notifier')
      expect(chef_run).to start_service('ceilometer-alarm-notifier')
    end

    describe 'ceilometer-alarm-notifier' do
      it 'subscribes to its config file' do
        expect(chef_run.service('ceilometer-alarm-notifier')).to subscribe_to('template[/etc/ceilometer/ceilometer.conf]').delayed
      end
    end
  end
end
