default['openstack']['telemetry-metric']['conf_secrets'] = {}

default['openstack']['telemetry-metric']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['rpc_backend'] = node['openstack']['mq']['service_type']
  # [keystone_authtoken] section
  conf['keystone_authtoken']['username'] = 'gnocchi'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['auth_type'] = 'password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['storage']['driver'] = 'file'
  if node['openstack']['telemetry-metric']['conf']['storage']['driver'] == 'file'
    conf['storage']['file_basepath'] = '/var/lib/gnocchi'
  end
end
