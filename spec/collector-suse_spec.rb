# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  before { telemetry_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      @chef_run.converge 'openstack-telemetry::collector'
    end

    it 'installs the collector package' do
      expect(@chef_run).to install_package 'openstack-ceilometer-collector'
    end

    it 'starts the collector service' do
      expect(@chef_run).to start_service 'openstack-ceilometer-collector'
    end
  end
end
