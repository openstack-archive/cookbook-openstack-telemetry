# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::agent-central' do
  before { metering_stubs }
  describe 'rhel' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-metering::agent-central'
    end

    expect_runs_common_recipe

    it 'installs the agent-central package' do
      expect(@chef_run).to install_package 'openstack-ceilometer-central'
    end

    it 'starts the agent-central service' do
      expect(@chef_run).to start_service 'openstack-ceilometer-central'
    end
  end
end
