Team and repository tags
========================

[![Team and repository tags](http://governance.openstack.org/badges/cookbook-openstack-telemetry.svg)](http://governance.openstack.org/reference/tags/index.html)

<!-- Change things from this point on -->

![Chef OpenStack Logo](https://www.openstack.org/themes/openstack/images/project-mascots/Chef%20OpenStack/OpenStack_Project_Chef_horizontal.png)

Description
===========

Installs the OpenStack Metering service **Ceilometer** as well as **Gnocchi** as
the backend for Metrics as part of the OpenStack reference deployment Chef for
OpenStack. Both are currently installed from packages.

http://docs.openstack.org/developer/ceilometer/
http://gnocchi.xyz/

Requirements
============

- Chef 12 or higher
- chefdk 0.9.0 or higher for testing (also includes berkshelf for cookbook
  dependency resolution)

WARNING:
- Currently there are no gnocchi packages included for Ubuntu Trusty. The
  gnocchi recipe will only work on Ubuntu Xenial and above.

Platform
========

- ubuntu
- redhat
- centos

Cookbooks
=========

The following cookbooks are dependencies:

- 'openstack-common', '>= 14.0.0'
- 'openstack-identity', '>= 14.0.0'
- 'openstackclient', '>= 0.1.0'

Attributes
==========

Please see the extensive inline documentation in `attributes/*.rb` for
descriptions of all the settable attributes for this cookbook.

Note that all attributes are in the `default['openstack']` "namespace"

The usage of attributes to generate the node.conf is decribed in the
openstack-common cookbook.

Recipes
=======

## agent-central
- Installs agent central service.

## agent-compute
- Installs agent compute service.

## agent-notification
- Installs agent notification service.

## api
- Installs API service.

## client
- Install the client packages

## collector
- Installs collector package and service. If the NoSQL database is used for metering service, ceilometer-upgrade will not be executed.

## common
- Common metering configuration.

## identity_registration
- Registers the endpoints, tenant and user for metering and metric service with Keystone.

## gnocchi
- Installs gnochhi as default backend for ceilometer metrics

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
| **Author**           |  Jan Klare (<j.klare@cloudbau.de>)                 |
| **Author**           |  Christoph Albers (<c.albers@x-ion.de>)            |
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
