name 'openstack-telemetry'
maintainer 'openstack-chef'
maintainer_email 'openstack-dev@lists.openstack.org'
issues_url 'https://launchpad.net/openstack-chef' if respond_to?(:issues_url)
source_url 'https://github.com/openstack/cookbook-openstack-telemetry' if respond_to?(:source_url)
license 'Apache 2.0'
description 'The OpenStack Metering service Ceilometer.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '14.0.1'

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

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'openstack-common', '>= 14.0.0'
depends 'openstack-identity', '>= 14.0.0'
depends 'openstackclient'
depends 'apache2', '~> 3.2'
