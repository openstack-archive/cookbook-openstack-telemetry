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
  conf['api']['port'] = bind_service.port
  conf['keystone_authtoken']['auth_url'] = auth_url
end

# merge all config options and secrets to be used in the gnocchi.conf
gnocchi_conf_options = merge_config_options 'telemetry-metric'
template node['openstack']['telemetry-metric']['conf_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['telemetry-metric']['user']
  group node['openstack']['telemetry-metric']['group']
  mode 00640
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
  mode 00640
end

# drop api-paste.ini to gnocchi folder (default ini will not use keystone auth)
cookbook_file File.join(node['openstack']['telemetry-metric']['conf_dir'], 'api-paste.ini') do
  source 'api-paste.ini'
  owner node['openstack']['telemetry-metric']['user']
  group node['openstack']['telemetry-metric']['group']
  mode 00640
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
      mode 00750
    end
  end
end

# dbsync for gnocchi
execute 'gnocchi-upgrade' do
  user node['openstack']['telemetry-metric']['user']
end

service 'gnocchi-api' do
  service_name platform['gnocchi-api_service']
  subscribes :restart, "template[#{node['openstack']['telemetry-metric']['conf_file']}]"
  action [:enable, :start]
end

service 'gnocchi-metricd' do
  service_name platform['gnocchi-metricd_service']
  subscribes :restart, "template[#{node['openstack']['telemetry-metric']['conf_file']}]"
  action [:enable, :start]
end
