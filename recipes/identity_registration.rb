# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: identity_registration
#
# Copyright 2013, AT&T Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity'

bootstrap_token = get_password 'token', 'openstack_identity_bootstrap_token'
auth_uri = ::URI.decode identity_admin_endpoint.to_s

%w(telemetry telemetry-metric).each do |telemetry_service|
  case telemetry_service
  when 'telemetry'
    service_name = 'ceilometer'
    service_type = 'metering'
  when 'telemetry-metric'
    service_name = 'gnocchi'
    service_type = 'metric'
  end

  admin_api_endpoint = admin_endpoint telemetry_service
  internal_api_endpoint = internal_endpoint telemetry_service
  public_api_endpoint = public_endpoint telemetry_service

  service_pass = get_password 'service', "openstack-#{telemetry_service}"
  service_role = node['openstack'][telemetry_service]['service_role']
  service_user =
    node['openstack'][telemetry_service]['conf']['keystone_authtoken']['username']
  service_tenant_name =
    node['openstack'][telemetry_service]['conf']['keystone_authtoken']['project_name']

  # Register Service Tenant
  openstack_identity_register "Register Service Tenant for #{telemetry_service}" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    tenant_name service_tenant_name
    tenant_description 'Service Tenant'

    action :create_tenant
  end

  # Register Service User
  openstack_identity_register "Register #{service_user} User" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    tenant_name service_tenant_name
    user_name service_user
    user_pass service_pass

    action :create_user
  end

  # Grant Admin role to Service User for Service Tenant
  openstack_identity_register "Grant 'admin' Role to #{service_user} User for Service Tenant" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    tenant_name service_tenant_name
    user_name service_user
    role_name service_role

    action :grant_role
  end

  openstack_identity_register "Register Service #{telemetry_service}" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    service_name service_name
    service_type service_type
    service_description 'Ceilometer Service'

    action :create_service
  end

  openstack_identity_register "Register #{service_type} Endpoint" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    service_type service_type
    endpoint_region node['openstack'][telemetry_service]['conf']['keystone_authtoken']['region_name']
    endpoint_adminurl ::URI.decode admin_api_endpoint.to_s
    endpoint_internalurl ::URI.decode internal_api_endpoint.to_s
    endpoint_publicurl ::URI.decode public_api_endpoint.to_s

    action :create_endpoint
  end
end
