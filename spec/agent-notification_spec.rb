require_relative 'spec_helper'

describe 'openstack-telemetry::agent-notification' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the agent-notification package' do
      expect(chef_run).to upgrade_package 'ceilometer-agent-notification'
    end

    it 'enables and starts ceilometer-agent-notification service' do
      expect(chef_run).to enable_service('ceilometer-agent-notification')
      expect(chef_run).to start_service('ceilometer-agent-notification')
    end

    describe 'ceilometer-agent-notification' do
      it 'subscribes to its config file' do
        expect(chef_run.service('ceilometer-agent-notification')).to \
          subscribe_to('template[/etc/ceilometer/ceilometer.conf]').delayed
      end
      it 'subscribes to /etc/ceilometer/pipeline.yaml' do
        expect(chef_run.service('ceilometer-agent-notification')).to \
          subscribe_to('template[/etc/ceilometer/pipeline.yaml]').delayed
      end
      it 'subscribes to /etc/ceilometer/polling.yaml' do
        expect(chef_run.service('ceilometer-agent-notification')).to \
          subscribe_to('template[/etc/ceilometer/polling.yaml]').delayed
      end
    end
  end
end
