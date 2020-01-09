# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::gnocchi_install' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    %w(
      gnocchi-api
      gnocchi-common
      gnocchi-metricd
      python3-gnocchi
      python3-gnocchiclient
    ).each do |p|
      it do
        expect(chef_run).to upgrade_package p
      end
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
