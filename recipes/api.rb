# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: api
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

require 'addressable'

# load the methods defined in cookbook-openstack-common libraries
class ::Chef::Recipe
  include ::Openstack
end

# include_recipe 'openstack-telemetry::common'

platform = node['openstack']['telemetry']['platform']
platform['api_packages'].each do |pkg|
  package pkg do
    options platform['package_overrides']
    action :upgrade
  end
end
# stop and disable the service ceilometer-api itself, since it should be run inside
# of apache
service platform['api_service'] do
  action [:stop, :disable]
end

bind_service = node['openstack']['bind_service']['all']['telemetry']
bind_service_address = bind_address bind_service
#### Start of Apache specific work

# configure attributes for apache2 cookbook to align with openstack settings
apache_listen = Array(node['apache']['listen']) # include already defined listen attributes
# Remove the default apache2 cookbook port, as that is also the default for horizon, but with
# a different address syntax.  *:80   vs  0.0.0.0:80
apache_listen -= ['*:80']
apache_listen += ["#{bind_service_address}:#{bind_service['port']}"]
node.normal['apache']['listen'] = apache_listen.uniq

# include the apache2 default recipe and the recipes for mod_wsgi
include_recipe 'apache2'
include_recipe 'apache2::mod_wsgi'
# include the apache2 mod_ssl recipe if ssl is enabled for identity
include_recipe 'apache2::mod_ssl' if node['openstack']['telemetry']['ssl']['enabled']

# create the ceilometer-api apache directory
ceilometer_apache_dir = "#{node['apache']['docroot_dir']}/ceilometer"
directory ceilometer_apache_dir do
  owner 'root'
  group 'root'
  mode 0o0755
end

ceilometer_server_entry = "#{ceilometer_apache_dir}/app"
# Note: Using lazy here as the wsgi file is not available until after
# the ceilometer-api package is installed during execution phase.
file ceilometer_server_entry do
  content lazy { IO.read(platform['ceilometer-api_wsgi_file']) }
  owner 'root'
  group 'root'
  mode 0o0755
end

web_app 'ceilometer-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'ceilometer-api'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry ceilometer_server_entry
  run_dir node['apache']['run_dir']
  log_dir node['apache']['log_dir']
  log_debug node['openstack']['telemetry']['debug']
  user node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  use_ssl node['openstack']['telemetry']['ssl']['enabled']
  cert_file node['openstack']['telemetry']['ssl']['certfile']
  chain_file node['openstack']['telemetry']['ssl']['chainfile']
  key_file node['openstack']['telemetry']['ssl']['keyfile']
  ca_certs_path node['openstack']['telemetry']['ssl']['ca_certs_path']
  cert_required node['openstack']['telemetry']['ssl']['cert_required']
  protocol node['openstack']['telemetry']['ssl']['protocol']
  ciphers node['openstack']['telemetry']['ssl']['ciphers']
end
