# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the collector package' do
      expect(chef_run).to install_package 'ceilometer-collector'
    end

    it 'executes ceilometer dbsync' do
      command = 'ceilometer-dbsync --config-file /etc/ceilometer/ceilometer.conf'
      expect(chef_run).to run_execute command
    end

    it 'does not execute ceilometer dbsync when nosql database is used' do
      node.set['openstack']['db']['telemetry']['nosql']['used'] = true

      expect(chef_run).not_to run_execute('execute[database migration]')
    end

    it 'installs python-mysqldb' do
      expect(chef_run).to install_package('python-mysqldb')
    end

    it 'starts and enables the collector service' do
      expect(chef_run).to enable_service('ceilometer-collector')
      expect(chef_run).to start_service('ceilometer-collector')
    end

    describe 'ceilometer-collector' do
      it 'subscribes to its config file' do
        expect(chef_run.service('ceilometer-collector')).to subscribe_to('template[/etc/ceilometer/ceilometer.conf]').delayed
      end
    end
  end
end
