# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  before { telemetry_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      @chef_run.converge 'openstack-telemetry::api'
    end

    it 'installs the api package' do
      expect(@chef_run).to install_package('openstack-ceilometer-api')
    end

    it 'starts api service' do
      expect(@chef_run).to start_service('openstack-ceilometer-api')
    end
  end
end
