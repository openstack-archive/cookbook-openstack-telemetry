# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'creates the /var/cache/ceilometer directory' do
      expect(chef_run).to create_directory('/var/cache/ceilometer').with(
        user: 'ceilometer',
        group: 'ceilometer',
        mode: 0700
      )
    end

    it 'installs the api package' do
      expect(chef_run).to upgrade_package 'ceilometer-api'
    end

    it 'enables and starts the api service' do
      expect(chef_run).to enable_service('ceilometer-api')
      expect(chef_run).to start_service('ceilometer-api')
    end

    describe 'ceilometer-api' do
      it 'subscribes to its config file' do
        expect(chef_run.service('ceilometer-api')).to subscribe_to('template[/etc/ceilometer/ceilometer.conf]').delayed
      end
    end
  end
end
