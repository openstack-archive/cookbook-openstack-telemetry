# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::setup' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it do
      expect(chef_run).to run_execute('ceilometer database migration')
        .with(
          command: 'ceilometer-upgrade --skip-gnocchi-resource-types --config-file /etc/ceilometer/ceilometer.conf'
        )
    end

    context 'Non-default upgrade_opts' do
      before do
        node.override['openstack']['telemetry']['upgrade_opts'] = ''
      end
      it do
        expect(chef_run).to run_execute('ceilometer database migration')
          .with(
            command: 'ceilometer-upgrade  --config-file /etc/ceilometer/ceilometer.conf'
          )
      end
    end
  end
end
