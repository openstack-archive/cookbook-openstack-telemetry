default['openstack']['aodh']['conf_secrets'] = {}

default['openstack']['aodh']['conf'].tap do |conf|
  # [keystone_authtoken] section
  conf['keystone_authtoken']['username'] = 'aodh'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['auth_type'] = 'v3password'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  # [service_credentials] section
  conf['service_credentials']['username'] = 'aodh'
  conf['service_credentials']['project_name'] = 'service'
  conf['service_credentials']['user_domain_name'] = 'Default'
  conf['service_credentials']['project_domain_name'] = 'Default'
  conf['service_credentials']['auth_type'] = 'v3password'
  conf['service_credentials']['interface'] = 'internal'
  conf['service_credentials']['region_name'] = node['openstack']['region']
end
