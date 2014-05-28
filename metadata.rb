name             'openstack-telemetry'
maintainer       'AT&T Services, Inc.'
maintainer_email 'cookbooks@lists.tfoundry.com'
license          'Apache 2.0'
description      'The OpenStack Metering service Ceilometer.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '9.1.1'

recipe 'openstack-telemetry::agent-central', 'Installs agent central service.'
recipe 'openstack-telemetry::agent-compute', 'Installs agent compute service.'
recipe 'openstack-telemetry::agent-notification', 'Installs the agent notification service.'
recipe 'openstack-telemetry::api', 'Installs API service.'
recipe 'openstack-telemetry::client', 'Installs client.'
recipe 'openstack-telemetry::collector', 'Installs collector service. If the NoSQL database is used for metering service, ceilometer-dbsync will not be executed.'
recipe 'openstack-telemetry::alarm-evaluator', 'Installs the alarm evaluator service.'
recipe 'openstack-telemetry::alarm-notifier', 'Installs the alarm notifier service.'
recipe 'openstack-telemetry::common', 'Common metering configuration.'
recipe 'openstack-telemetry::identity_registration', 'Registers the endpoints, tenant and user for metering service with Keystone'

%w{ ubuntu suse }.each do |os|
  supports os
end

depends 'openstack-common', '~> 9.0'
depends 'openstack-identity', '~> 9.0'
depends 'openstack-compute', '~> 9.0'
