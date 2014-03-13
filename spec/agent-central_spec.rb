# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::agent-central' do
  before { telemetry_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      @chef_run.converge 'openstack-telemetry::agent-central'
    end

    expect_runs_common_recipe

    it 'installs the agent-central package' do
      expect(@chef_run).to install_package 'ceilometer-agent-central'
    end

    it 'starts agent-central service' do
      expect(@chef_run).to start_service('ceilometer-agent-central')
    end
  end
end
