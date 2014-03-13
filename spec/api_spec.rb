# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  before { telemetry_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      @chef_run.converge 'openstack-telemetry::api'
    end

    expect_runs_common_recipe

    it 'creates the /var/cache/ceilometer directory' do
      expect(@chef_run).to create_directory('/var/cache/ceilometer').with(
        user: 'ceilometer',
        group: 'ceilometer',
        mode: 0700
        )
    end

    it 'starts api service' do
      expect(@chef_run).to start_service('ceilometer-api')
    end

    it 'starts api service' do
      expect(@chef_run).to start_service('ceilometer-api')
    end
  end
end
