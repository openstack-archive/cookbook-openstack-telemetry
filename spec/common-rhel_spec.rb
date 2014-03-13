# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  before { telemetry_stubs }
  describe 'rhel' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-telemetry::common'
    end

    it 'installs the common package' do
      expect(@chef_run).to install_package 'openstack-ceilometer-common'
    end
  end
end
