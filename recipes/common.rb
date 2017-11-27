# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: common
#
# Copyright 2013, AT&T Services, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright 2013-2014, SUSE Linux GmbH
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

class ::Chef::Recipe
  include ::Openstack
end

if node['openstack']['telemetry']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform = node['openstack']['telemetry']['platform']

db_type = node['openstack']['db']['telemetry']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
  end
end

platform['common_packages'].each do |pkg|
  package pkg do
    options platform['package_overrides']
    action :upgrade
  end
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['telemetry']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'telemetry'
end

db_user = node['openstack']['db']['telemetry']['username']
db_pass = get_password 'db', 'ceilometer'
bind_service = node['openstack']['bind_service']['all']['telemetry']
bind_service_address = bind_address bind_service

# define secrets that are needed in the ceilometer.conf
node.default['openstack']['telemetry']['conf_secrets'].tap do |conf_secrets|
  conf_secrets['database']['connection'] =
    db_uri('telemetry', db_user, db_pass)
  conf_secrets['service_credentials']['password'] =
    get_password 'service', 'openstack-telemetry'
  conf_secrets['keystone_authtoken']['password'] =
    get_password 'service', 'openstack-telemetry'
end

identity_public_endpoint = public_endpoint 'identity'
auth_url =
  auth_uri_transform(
    identity_public_endpoint.to_s,
    node['openstack']['telemetry']['identity-api']['auth']['version']
  )

node.default['openstack']['telemetry']['conf'].tap do |conf|
  conf['api']['host'] = bind_service_address
  conf['api']['port'] = bind_service['port']
  conf['keystone_authtoken']['auth_url'] = auth_url
  conf['service_credentials']['auth_url'] = auth_url
  conf['dispatcher_gnocchi']['url'] = public_endpoint 'telemetry-metric'
  conf['dispatcher_gnocchi']['filter_project'] = 'service'
end

directory node['openstack']['telemetry']['conf_dir'] do
  owner node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  mode 0o0750
  action :create
end

directory "#{node['apache']['run_dir']}/ceilometer" do
  owner node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  mode 0o0750
  recursive true
  action :create
end

# merge all config options and secrets to be used in the ceilometer.conf
ceilometer_conf_options = merge_config_options 'telemetry'

template node['openstack']['telemetry']['conf_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  mode 0o0640
  variables(
    service_config: ceilometer_conf_options
  )
end
