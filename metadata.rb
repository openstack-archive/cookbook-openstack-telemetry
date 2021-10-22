name             'openstack-telemetry'
maintainer       'openstack-chef'
maintainer_email 'openstack-discuss@lists.openstack.org'
license          'Apache-2.0'
description      'The OpenStack Metering service Ceilometer.'
version          '20.0.0'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.6'
depends 'openstackclient'
depends 'openstack-common', '>= 20.0.0'
depends 'openstack-identity', '>= 20.0.0'

issues_url 'https://launchpad.net/openstack-chef'
source_url 'https://opendev.org/openstack/cookbook-openstack-telemetry'
chef_version '>= 16.0'
