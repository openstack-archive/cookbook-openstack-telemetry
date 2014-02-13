# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::agent-compute' do
  before { metering_stubs }
  describe 'rhel' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-metering::agent-compute'
    end

    expect_runs_common_recipe

    it 'installs the agent-compute package' do
      expect(@chef_run).to install_package 'openstack-ceilometer-compute'
    end

    it 'starts ceilometer-agent-compute service' do
      expect(@chef_run).to start_service('openstack-ceilometer-compute')
    end
  end
end
