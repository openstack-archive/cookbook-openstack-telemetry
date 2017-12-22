# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: gnocchi_configure
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
platform = node['openstack']['telemetry']['platform']
db_user = node['openstack']['db']['telemetry-metric']['username']
db_pass = get_password 'db', 'gnocchi'
bind_service = node['openstack']['bind_service']['all']['telemetry-metric']
bind_service_address = bind_address bind_service

# define secrets that are needed in the gnocchi.conf
node.default['openstack']['telemetry-metric']['conf_secrets'].tap do |conf_secrets|
  conf_secrets['database']['connection'] =
    db_uri('telemetry-metric', db_user, db_pass)
  conf_secrets['indexer']['url'] =
    db_uri('telemetry-metric', db_user, db_pass)
  conf_secrets['keystone_authtoken']['password'] =
    get_password 'service', 'openstack-telemetry-metric'
end

identity_public_endpoint = public_endpoint 'identity'
auth_url =
  auth_uri_transform(
    identity_public_endpoint.to_s,
    node['openstack']['telemetry-metric']['identity-api']['auth']['version']
  )

node.default['openstack']['telemetry-metric']['conf'].tap do |conf|
  conf['api']['host'] = bind_service_address
  conf['api']['port'] = bind_service['port']
  conf['keystone_authtoken']['auth_url'] = auth_url
end

# merge all config options and secrets to be used in the gnocchi.conf
gnocchi_conf_options = merge_config_options 'telemetry-metric'
template node['openstack']['telemetry-metric']['conf_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['telemetry-metric']['user']
  group node['openstack']['telemetry-metric']['group']
  mode 0o0640
  variables(
    service_config: gnocchi_conf_options
  )
end

# drop gnocchi_resources.yaml to ceilometer folder (current workaround since not
# included in ubuntu package)
cookbook_file File.join(node['openstack']['telemetry']['conf_dir'], 'gnocchi_resources.yaml') do
  source 'gnocchi_resources.yaml'
  owner node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  mode 0o0640
end

# drop api-paste.ini to gnocchi folder (default ini will not use keystone auth)
cookbook_file File.join(node['openstack']['telemetry-metric']['conf_dir'], 'api-paste.ini') do
  source 'api-paste.ini'
  owner node['openstack']['telemetry-metric']['user']
  group node['openstack']['telemetry-metric']['group']
  mode 0o0640
end

# drop event_pipeline.yaml to ceilometer folder (gnocchi does not use events and
# the default event_pipeline.yaml will lead to a queue "event.sample" in rabbit
# without a consumer)
cookbook_file File.join(node['openstack']['telemetry']['conf_dir'], 'event_pipeline.yaml') do
  source 'event_pipeline.yaml'
  owner node['openstack']['telemetry']['user']
  group node['openstack']['telemetry']['group']
  mode 0o0640
end

if node['openstack']['telemetry-metric']['conf']['storage']['driver'] == 'file'
  # default store is file, so create needed directories with correct permissions
  # (on ubuntu they are created by the package, but owned by root and not writable
  # for gnocchi)
  store_path = node['openstack']['telemetry-metric']['conf']['storage']['file_basepath']
  %w(tmp measure cache).each do |dir|
    directory File.join(store_path, dir) do
      owner node['openstack']['telemetry-metric']['user']
      group node['openstack']['telemetry-metric']['group']
      recursive true
      mode 0o0750
    end
  end
end

# dbsync for gnocchi
execute 'run gnocchi-upgrade' do
  command "gnocchi-upgrade #{node['openstack']['telemetry-metric']['gnocchi-upgrade-options']}"
  user node['openstack']['telemetry-metric']['user']
end

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
include_recipe 'apache2::mod_ssl' if node['openstack']['identity']['ssl']['enabled']

# create the gnocchi-api apache directory
gnocchi_apache_dir = "#{node['apache']['docroot_dir']}/gnocchi"
directory gnocchi_apache_dir do
  owner 'root'
  group 'root'
  mode 0o0755
end

gnocchi_server_entry = "#{gnocchi_apache_dir}/app"
# Note: Using lazy here as the wsgi file is not available until after
# the gnocchik-api package is installed during execution phase.
file gnocchi_server_entry do
  content lazy { IO.read(platform['gnocchi-api_wsgi_file']) }
  owner 'root'
  group 'root'
  mode 0o0755
end

web_app 'gnocchi-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'gnocchi-api'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry gnocchi_server_entry
  run_dir node['apache']['run_dir']
  log_dir node['apache']['log_dir']
  log_debug node['openstack']['telemetry-metric']['debug']
  user node['openstack']['telemetry-metric']['user']
  group node['openstack']['telemetry-metric']['group']
  use_ssl node['openstack']['telemetry-metric']['ssl']['enabled']
  cert_file node['openstack']['telemetry-metric']['ssl']['certfile']
  chain_file node['openstack']['telemetry-metric']['ssl']['chainfile']
  key_file node['openstack']['telemetry-metric']['ssl']['keyfile']
  ca_certs_path node['openstack']['telemetry-metric']['ssl']['ca_certs_path']
  cert_required node['openstack']['telemetry-metric']['ssl']['cert_required']
  protocol node['openstack']['telemetry-metric']['ssl']['protocol']
  ciphers node['openstack']['telemetry-metric']['ssl']['ciphers']
end

service 'gnocchi-metricd' do
  service_name platform['gnocchi-metricd_service']
  subscribes :restart, "template[#{node['openstack']['telemetry-metric']['conf_file']}]"
  action [:enable, :start]
end
