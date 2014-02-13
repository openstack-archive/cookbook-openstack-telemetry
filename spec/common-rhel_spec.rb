# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::common' do
  before { metering_stubs }
  describe 'rhel' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-metering::common'
    end

    it 'installs the common package' do
      expect(@chef_run).to install_package 'openstack-ceilometer-common'
    end
  end
end
