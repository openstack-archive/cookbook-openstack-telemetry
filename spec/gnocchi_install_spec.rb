# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::gnocchi_install' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it do
      expect(chef_run).to upgrade_package 'gnocchi-api'
    end

    it do
      expect(chef_run).to stop_service('gnocchi-api')
      expect(chef_run).to disable_service('gnocchi-api')
    end

    it do
      expect(chef_run).to upgrade_package 'gnocchi-metricd'
    end
  end
end
