Description
===========

Installs the OpenStack Metering service **Ceilometer** as part of the OpenStack
reference deployment Chef for OpenStack.  Ceilometer is currently installed
from packages.

https://wiki.openstack.org/wiki/Ceilometer

Requirements
============

Cookbooks
---------

The following cookbooks are dependencies:

* openstack-common
* openstack-identity
* openstack-compute

Usage
=====

agent-central
----
- Installs agent central service.

agent-compute
----
- Installs agent compute service.

agent-notification
----
- Installs agent notification service.

alarm-evaluator
----
- Installs alarm evaluator service.

alarm-notifier
----
- Installs alarm notifier service.

api
----
- Installs API service.

client
----
- Install the client packages

collector
----
- Installs collector package and service. If the NoSQL database is used for metering service, ceilometer-dbsync will not be executed.

common
----
- Common metering configuration.

identity_registration
----
- Registers the endpoints, tenant and user for metering service with Keystone.

Attributes
==========

* `openstack['telemetry']['api']['auth']['version']` - Select v2.0 or v3.0. Default v2.0. The auth API version used to interact with identity service.
* `openstack['telemetry']['sample_source']` -  The source name of emitted samples, default value is openstack.
* `openstack['telemetry']['api']['auth']['memcached_servers']` - A list of memcached server(s) to use for caching
* `openstack['telemetry']['api']['auth']['memcache_security_strategy']` - Whether token data should be authenticated or authenticated and encrypted. Acceptable values are MAC or ENCRYPT
* `openstack['telemetry']['api']['auth']['memcache_secret_key']` - This string is used for key derivation
* `openstack['telemetry']['api']['auth']['hash_algorithms']` - Hash algorithms to use for hashing PKI tokens
* `openstack['telemetry']['api']['auth']['cafile']` - A PEM encoded Certificate Authority to use when verifying HTTPs connections
* `openstack['telemetry']['api']['auth']['insecure']` - Set whether to verify HTTPS connections
* `openstack['telemetry']['service-credentials']['cafile']` - A PEM encoded Certificate Authority to use when verifying HTTPs connections (for service polling authentication)
* `openstack['telemetry']['service-credentials']['insecure']` - Set whether to verify HTTPS connections (for service polling authentication)
* `openstack['telemetry']['dbsync_timeout']` - Set dbsync command timeout value
* `openstack['telemetry']['database']['time_to_live']` - Set a time_to_live parameter (ttl) for samples. Set -1 for no expiry
* `openstack['telemetry']['notification']['store_events']` - Set a store_events parameter for notification service

The following attributes are defined in attributes/default.rb of the common cookbook, but are documented here due to their relevance:

* `openstack['endpoints']['telemetry-api-bind']['host']` - The IP address to bind the api service to
* `openstack['endpoints']['telemetry-api-bind']['port']` - The port to bind the api service to
* `openstack['endpoints']['telemetry-api-bind']['bind_interface']` - The interface name to bind the api service to

If the value of the 'bind_interface' attribute is non-nil, then the telemetry service will be bound to the first IP address on that interface.  If the value of the 'bind_interface' attribute is nil, then the telemetry service will be bound to the IP address specifie

Testing
=====

Please refer to the [TESTING.md](TESTING.md) for instructions for testing the cookbook.

Berkshelf
=====

Berks will resolve version requirements and dependencies on first run and
store these in Berksfile.lock. If new cookbooks become available you can run
`berks update` to update the references in Berksfile.lock. Berksfile.lock will
be included in stable branches to provide a known good set of dependencies.
Berksfile.lock will not be included in development branches to encourage
development against the latest cookbooks.

License and Author
==================

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |  Matt Ray (<matt@opscode.com>)                     |
| **Author**           |  John Dewey (<jdewey@att.com>)                     |
| **Author**           |  Justin Shepherd (<jshepher@rackspace.com>)        |
| **Author**           |  Salman Baset (<sabaset@us.ibm.com>)               |
| **Author**           |  Ionut Artarisi (<iartarisi@suse.cz>)              |
| **Author**           |  Eric Zhou (<zyouzhou@cn.ibm.com>)                 |
| **Author**           |  Chen Zhiwei (<zhiwchen@cn.ibm.com>)               |
| **Author**           |  David Geng (<gengjh@cn.ibm.com>)                  |
| **Author**           |  Mark Vanderwiel (<vanderwl@us.ibm.com>)           |
| **Author**           |  Jan Klare (<j.klare@x-ion.de>)                    |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2013, Opscode, Inc.                 |
| **Copyright**        |  Copyright (c) 2013, AT&T Services, Inc.           |
| **Copyright**        |  Copyright (c) 2013, Rackspace US, Inc.            |
| **Copyright**        |  Copyright (c) 2013-2014, IBM, Corp.               |
| **Copyright**        |  Copyright (c) 2013-2014, SUSE Linux GmbH          |


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
