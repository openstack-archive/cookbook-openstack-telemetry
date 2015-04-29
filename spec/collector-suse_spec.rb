# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the collector package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer-collector'
    end

    it 'starts the collector service' do
      expect(chef_run).to start_service 'openstack-ceilometer-collector'
    end
  end
end
