name             'openstack-telemetry'
maintainer       'openstack-chef'
maintainer_email 'openstack-discuss@lists.openstack.org'
license          'Apache-2.0'
description      'The OpenStack Metering service Ceilometer.'
version          '18.0.0'

recipe 'openstack-telemetry::agent-central', 'Installs agent central service.'
recipe 'openstack-telemetry::agent-compute', 'Installs agent compute service.'
recipe 'openstack-telemetry::agent-notification', 'Installs the agent notification service.'
recipe 'openstack-telemetry::aodh', 'Installs aodh service'
recipe 'openstack-telemetry::api', 'Installs API service.'
recipe 'openstack-telemetry::common', 'Common metering configuration.'
recipe 'openstack-telemetry::gnocchi_configure', 'Configure Gnocchi'
recipe 'openstack-telemetry::gnocchi_install', 'Installs and starts the Gnocchi service'
recipe 'openstack-telemetry::identity_registration', 'Registers the endpoints, tenant and user for metering service with Keystone'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.0'
depends 'openstackclient'
depends 'openstack-common', '>= 18.0.0'
depends 'openstack-identity', '>= 18.0.0'

issues_url 'https://launchpad.net/openstack-chef'
source_url 'https://opendev.org/openstack/cookbook-openstack-telemetry'
chef_version '>= 14.0'
