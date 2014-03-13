# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  before { telemetry_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      @chef_run.converge 'openstack-telemetry::common'
    end

    it 'installs the common package' do
      expect(@chef_run).to install_package 'openstack-ceilometer'
    end
  end
end
