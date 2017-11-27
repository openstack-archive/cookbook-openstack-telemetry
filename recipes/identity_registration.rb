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

# Include OS
class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity'

auth_url = ::URI.decode identity_admin_endpoint.to_s
admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', node['openstack']['identity']['admin_user']
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']
service_domain_name = node['openstack']['telemetry']['conf']['keystone_authtoken']['user_domain_name']
connection_params = {
  openstack_auth_url:     "#{auth_url}/auth/tokens",
  openstack_username:     admin_user,
  openstack_api_key:      admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name:    admin_domain,
}

%w(telemetry telemetry-metric).each do |telemetry_service|
  case telemetry_service
  when 'telemetry'
    service_name = 'ceilometer'
    service_type = 'metering'
  when 'telemetry-metric'
    service_name = 'gnocchi'
    service_type = 'metric'

  end
  interfaces = {
    public: { url: public_endpoint(telemetry_service) },
    internal: { url: internal_endpoint(telemetry_service) },
    admin: { url: admin_endpoint(telemetry_service) },
  }

  service_pass = get_password 'service', "openstack-#{telemetry_service}"
  service_role = node['openstack'][telemetry_service]['service_role']
  service_user =
    node['openstack'][telemetry_service]['conf']['keystone_authtoken']['username']
  service_tenant_name =
    node['openstack'][telemetry_service]['conf']['keystone_authtoken']['project_name']
  region = node['openstack']['region']

  # Register telemetry_service Service
  openstack_service service_name do
    type service_type
    connection_params connection_params
  end

  interfaces.each do |interface, res|
    # Register telemetry_service Endpoints
    openstack_endpoint service_type do
      service_name service_name
      interface interface.to_s
      url res[:url].to_s
      region region
      connection_params connection_params
    end
  end

  # Register Service Tenant
  openstack_project service_tenant_name do
    connection_params connection_params
  end

  # Register Service User
  openstack_user service_user do
    domain_name service_domain_name
    role_name service_role
    project_name service_tenant_name
    password service_pass
    connection_params connection_params
    action [:create, :grant_role]
  end
end
