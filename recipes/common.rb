# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: common
#
# Copyright 2013, AT&T Services, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright 2013, SUSE Linux GmbH
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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

if node['openstack']['telemetry']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform = node['openstack']['telemetry']['platform']

db_type = node['openstack']['db']['telemetry']['service_type']
platform["#{db_type}_python_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

platform['common_packages'].each do |pkg|
  package pkg do
    options platform['package_overrides']
  end
end

mq_service_type = node['openstack']['mq']['telemetry']['service_type']

if mq_service_type == 'rabbitmq'
  mq_password = get_password 'user', node['openstack']['mq']['telemetry']['rabbit']['userid']
elsif mq_service_type == 'qpid'
  mq_password = get_password 'user', node['openstack']['mq']['telemetry']['qpid']['username']
end

db_user = node['openstack']['db']['telemetry']['username']
db_pass = get_password 'db', 'ceilometer'
db_uri = db_uri('telemetry', db_user, db_pass).to_s

service_user = node['openstack']['telemetry']['service_user']
service_pass = get_password 'service', 'openstack-ceilometer'
service_tenant = node['openstack']['telemetry']['service_tenant_name']

identity_endpoint = endpoint 'identity-api'
identity_admin_endpoint = endpoint 'identity-admin'
image_endpoint = endpoint 'image-api'
telemetry_api_bind = endpoint 'telemetry-api-bind'

auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['telemetry']['api']['auth']['version']

Chef::Log.debug("openstack-telemetry::common:service_user|#{service_user}")
Chef::Log.debug("openstack-telemetry::common:service_tenant|#{service_tenant}")
Chef::Log.debug("openstack-telemetry::common:identity_endpoint|#{identity_endpoint.to_s}")

metering_secret = get_secret 'openstack_metering_secret'

directory node['openstack']['telemetry']['conf_dir'] do
  owner node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  mode  00750

  action :create
end

template node['openstack']['telemetry']['conf'] do
  source 'ceilometer.conf.erb'
  owner  node['openstack']['telemetry']['user']
  group  node['openstack']['telemetry']['group']
  mode   00640

  variables(
    auth_uri: auth_uri,
    database_connection: db_uri,
    image_endpoint: image_endpoint,
    identity_endpoint: identity_endpoint,
    identity_admin_endpoint: identity_admin_endpoint,
    mq_service_type: mq_service_type,
    mq_password: mq_password,
    service_pass: service_pass,
    service_tenant_name: service_tenant,
    service_user: service_user,
    metering_secret: metering_secret,
    api_bind_host: telemetry_api_bind.host,
    api_bind_port: telemetry_api_bind.port
  )
end
