# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::identity_registration' do
  before do
    metering_stubs
    @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
    @chef_run.converge 'openstack-metering::identity_registration'
  end

  it 'registers metering service' do
    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Register Metering Service'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      service_name: 'ceilometer',
      service_type: 'metering',
      action: [:create_service]
    )
  end

  it 'registers metering endpoint' do
    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Register Metering Endpoint'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      service_type: 'metering',
      endpoint_region: 'RegionOne',
      endpoint_adminurl: 'http://127.0.0.1:8777',
      endpoint_internalurl: 'http://127.0.0.1:8777',
      endpoint_publicurl: 'http://127.0.0.1:8777',
      action: [:create_endpoint]
    )
  end

  it 'overrides metering endpoint region' do
    @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
      n.set['openstack']['metering']['region'] = 'meteringRegion'
    end
    @chef_run.converge 'openstack-metering::identity_registration'

    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Register Metering Endpoint'
    ).to_hash

    expect(resource).to include(
      endpoint_region: 'meteringRegion',
      action: [:create_endpoint]
    )
  end
end
