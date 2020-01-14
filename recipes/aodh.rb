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
  include Apache2::Cookbook::Helpers
end

include_recipe 'openstack-telemetry::common'

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
auth_url = ::URI.decode identity_public_endpoint.to_s

node.default['openstack']['aodh']['conf'].tap do |conf|
  conf['api']['host'] = bind_service_address
  conf['api']['port'] = bind_service['port']
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
  notifies :restart, 'service[apache2]'
end

execute 'run aodh-dbsync' do
  command 'aodh-dbsync '
  user node['openstack']['aodh']['user']
  group node['openstack']['aodh']['group']
end

#### Start of Apache specific work

# Finds and appends the listen port to the apache2_install[openstack]
# resource which is defined in openstack-identity::server-apache.
apache_resource = find_resource(:apache2_install, 'openstack')

if apache_resource
  apache_resource.listen = [apache_resource.listen, "#{bind_service['host']}:#{bind_service['port']}"].flatten
else
  apache2_install 'openstack' do
    listen "#{bind_service['host']}:#{bind_service['port']}"
  end
end

apache2_module 'wsgi'
apache2_module 'ssl' if node['openstack']['aodh']['ssl']['enabled']

# create the aodh-api apache directory
aodh_apache_dir = "#{default_docroot_dir}/aodh"
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

template "#{apache_dir}/sites-available/aodh-api.conf" do
  extend Apache2::Cookbook::Helpers
  source 'wsgi-template.conf.erb'
  variables(
    daemon_process: 'aodh-api',
    server_host: bind_service['host'],
    server_port: bind_service['port'],
    server_entry: aodh_server_entry,
    run_dir: lock_dir,
    log_dir: default_log_dir,
    user: node['openstack']['aodh']['user'],
    group: node['openstack']['aodh']['group'],
    use_ssl: node['openstack']['aodh']['ssl']['enabled'],
    cert_file: node['openstack']['aodh']['ssl']['certfile'],
    chain_file: node['openstack']['aodh']['ssl']['chainfile'],
    key_file: node['openstack']['aodh']['ssl']['keyfile'],
    ca_certs_path: node['openstack']['aodh']['ssl']['ca_certs_path'],
    cert_required: node['openstack']['aodh']['ssl']['cert_required'],
    protocol: node['openstack']['aodh']['ssl']['protocol'],
    ciphers: node['openstack']['aodh']['ssl']['ciphers']
  )
  notifies :restart, 'service[apache2]'
end

apache2_site 'aodh-api' do
  notifies :restart, 'service[apache2]', :immediately
end

platform['aodh_services'].each do |aodh_service|
  service aodh_service do
    service_name aodh_service
    subscribes :restart, "template[#{node['openstack']['aodh']['conf_file']}]"
    action [:enable, :start]
  end
end
