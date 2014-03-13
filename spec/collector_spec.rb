# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-telemetry::collector' do
  before { telemetry_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      @chef_run.converge 'openstack-telemetry::collector'
    end

    expect_runs_common_recipe

    it 'executes ceilometer dbsync' do
      command = 'ceilometer-dbsync --config-file /etc/ceilometer/ceilometer.conf'
      expect(@chef_run).to run_execute command
    end

    it 'does not execute ceilometer dbsync when nosql database is used' do
      @chef_run.node.set['openstack']['db']['telemetry']['nosql']['used'] = true
      resource = 'execute[database migration]'
      expect(@chef_run).not_to run_execute resource
    end

    it 'installs python-mysqldb', A: true do
      expect(@chef_run).to install_package 'python-mysqldb'
    end

    it 'starts collector service' do
      expect(@chef_run).to start_service('ceilometer-collector')
    end
  end
end
