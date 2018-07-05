# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: aodh
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

# load the methods defined in cookbook-openstack-common libraries
class ::Chef::Recipe
  include ::Openstack
end

platform = node['openstack']['aodh']['platform']
platform['aodh_packages'].each do |pkg|
  package pkg do
    options platform['package_overrides']
    action :upgrade
  end
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['aodh']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'aodh'
end

db_user = node['openstack']['db']['aodh']['username']
db_pass = get_password 'db', 'aodh'
bind_service = node['openstack']['bind_service']['all']['aodh']
bind_service_address = bind_address bind_service

node.default['openstack']['aodh']['conf_secrets'].tap do |conf_secrets|
  conf_secrets['database']['connection'] =
    db_uri('aodh', db_user, db_pass)
  conf_secrets['service_credentials']['password'] =
    get_password 'service', 'openstack-aodh'
  conf_secrets['keystone_authtoken']['password'] =
    get_password 'service', 'openstack-aodh'
end

identity_public_endpoint = public_endpoint 'identity'
auth_url =
  auth_uri_transform(
    identity_public_endpoint.to_s,
    node['openstack']['aodh']['identity-api']['auth']['version']
  )

node.default['openstack']['aodh']['conf'].tap do |conf|
  conf['api']['host'] = bind_service_address
  conf['api']['port'] = bind_service.port
  conf['keystone_authtoken']['auth_url'] = auth_url
  conf['service_credentials']['auth_url'] = auth_url
  conf['keystone_authtoken']['memcache_servers'] = memcached_servers.join ','
end

directory node['openstack']['aodh']['conf_dir'] do
  owner node['openstack']['aodh']['user']
  group node['openstack']['aodh']['group']
  mode 0o0750
  action :create
end

# merge all config options and secrets to be used in the aodh.conf
aodh_conf_options = merge_config_options 'aodh'

template node['openstack']['aodh']['conf_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['aodh']['user']
  group node['openstack']['aodh']['group']
  mode 0o0640
  variables(
    service_config: aodh_conf_options
  )
end

execute 'run aodh-dbsync' do
  command 'aodh-dbsync '
  user node['openstack']['aodh']['user']
end

#### Start of Apache specific work

# configure attributes for apache2 cookbook to align with openstack settings
apache_listen = Array(node['apache']['listen']) # include already defined listen attributes
# Remove the default apache2 cookbook port, as that is also the default for horizon, but with
# a different address syntax.  *:80   vs  0.0.0.0:80
apache_listen -= ['*:80']
apache_listen += ["#{bind_service_address}:#{bind_service.port}"]
node.normal['apache']['listen'] = apache_listen.uniq

# include the apache2 default recipe and the recipes for mod_wsgi
include_recipe 'apache2'
include_recipe 'apache2::mod_wsgi'
# include the apache2 mod_ssl recipe if ssl is enabled for identity
include_recipe 'apache2::mod_ssl' if node['openstack']['aodh']['ssl']['enabled']

# create the aodh-api apache directory
aodh_apache_dir = "#{node['apache']['docroot_dir']}/aodh"
directory aodh_apache_dir do
  owner 'root'
  group 'root'
  mode 0o0755
end

aodh_server_entry = "#{aodh_apache_dir}/app"
# Note: Using lazy here as the wsgi file is not available until after
# the aodh-common package is installed during execution phase.
file aodh_server_entry do
  content lazy { IO.read(platform['aodh-api_wsgi_file']) }
  owner 'root'
  group 'root'
  mode 0o0755
end

web_app 'aodh-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'aodh-api'
  server_host bind_service.host
  server_port bind_service.port
  server_entry aodh_server_entry
  run_dir node['apache']['run_dir']
  log_dir node['apache']['log_dir']
  log_debug node['openstack']['aodh']['debug']
  user node['openstack']['aodh']['user']
  group node['openstack']['aodh']['group']
  use_ssl node['openstack']['aodh']['ssl']['enabled']
  cert_file node['openstack']['aodh']['ssl']['certfile']
  chain_file node['openstack']['aodh']['ssl']['chainfile']
  key_file node['openstack']['aodh']['ssl']['keyfile']
  ca_certs_path node['openstack']['aodh']['ssl']['ca_certs_path']
  cert_required node['openstack']['aodh']['ssl']['cert_required']
  protocol node['openstack']['aodh']['ssl']['protocol']
  ciphers node['openstack']['aodh']['ssl']['ciphers']
end

platform['aodh_services'].each do |aodh_service|
  service aodh_service do
    service_name aodh_service
    subscribes :restart, "template[#{node['openstack']['aodh']['conf_file']}]"
    action [:enable, :start]
  end
end
