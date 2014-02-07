# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::collector' do
  before { metering_stubs }
  describe 'rhel' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-metering::collector'
    end

    expect_runs_common_recipe

    it 'executes ceilometer dbsync' do
      command = 'ceilometer-dbsync --config-file /etc/ceilometer/ceilometer.conf'
      expect(@chef_run).to run_execute command
    end

    it 'installs the collector package' do
      expect(@chef_run).to install_package('openstack-ceilometer-collector')
    end

    it 'starts collector service' do
      expect(@chef_run).to start_service('openstack-ceilometer-collector')
    end
  end
end
