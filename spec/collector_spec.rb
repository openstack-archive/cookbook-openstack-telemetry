# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it do
      expect(chef_run).to upgrade_package 'ceilometer-collector'
    end

    it do
      expect(chef_run).to upgrade_package('python-mysqldb')
    end

    it do
      expect(chef_run).to enable_service('ceilometer-collector')
    end

    it do
      expect(chef_run).to start_service('ceilometer-collector')
    end

    describe 'ceilometer-collector' do
      it 'subscribes to its config file' do
        expect(chef_run.service('ceilometer-collector')).to subscribe_to('template[/etc/ceilometer/ceilometer.conf]').delayed
      end
    end
  end
end
