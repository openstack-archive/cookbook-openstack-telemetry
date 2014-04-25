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
TODO: Add DB2 support on other platforms
* `openstack['telemetry']['platform']['db2_python_packages']` - Array of DB2 python packages, only available on redhat platform

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
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2013, Opscode, Inc.                 |
| **Copyright**        |  Copyright (c) 2013, AT&T Services, Inc.           |
| **Copyright**        |  Copyright (c) 2013, Rackspace US, Inc.            |
| **Copyright**        |  Copyright (c) 2013-2014, IBM, Corp.               |
| **Copyright**        |  Copyright (c) 2013, SUSE Linux GmbH               |


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
