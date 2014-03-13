# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::agent-central' do
  before { telemetry_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      @chef_run.converge 'openstack-telemetry::agent-central'
    end

    it 'installs the agent-central package' do
      expect(@chef_run).to install_package 'openstack-ceilometer-agent-central'
    end

    it 'starts the agent-central service' do
      expect(@chef_run).to start_service 'openstack-ceilometer-agent-central'
    end
  end
end
