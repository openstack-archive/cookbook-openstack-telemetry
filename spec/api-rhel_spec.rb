# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::api' do
  before { metering_stubs }
  describe 'rhel' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-metering::api'
    end

    expect_runs_common_recipe

    it 'creates the /var/cache/ceilometer directory' do
      expect(@chef_run).to create_directory('/var/cache/ceilometer').with(
        user: 'ceilometer',
        group: 'ceilometer',
        mode: 0700
        )
    end

    it 'installs the api package' do
      expect(@chef_run).to install_package('openstack-ceilometer-api')
    end

    it 'starts api service' do
      expect(@chef_run).to start_service('openstack-ceilometer-api')
    end
  end
end
