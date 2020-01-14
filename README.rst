OpenStack Chef Cookbook - telemetry
===================================

.. image:: https://governance.openstack.org/badges/cookbook-openstack-telemetry.svg
    :target: https://governance.openstack.org/reference/tags/index.html

Description
===========

Installs the OpenStack Metering service **Ceilometer** as well as
**Gnocchi** as the backend for Metrics as part of the OpenStack
reference deployment Chef for OpenStack. The `OpenStack chef-repo`_
contains documentation for using this cookbook in the context of a full
OpenStack deployment. Both are currently installed from packages.

.. _OpenStack chef-repo: https://opendev.org/openstack/openstack-chef

https://docs.openstack.org/ceilometer/latest/

https://gnocchi.xyz/

Requirements
============

- Chef 14 or higher
- ChefDK 3.2.30 for testing (also includes Berkshelf for cookbook
  dependency resolution)

Platform
========

- ubuntu
- redhat
- centos

Cookbooks
=========

The following cookbooks are dependencies:

- 'openstackclient', '>= 0.1.0'
- 'openstack-common', '>= 18.0.0'
- 'openstack-identity', '>= 18.0.0'

Attributes
==========

Please see the extensive inline documentation in ``attributes/*.rb`` for
descriptions of all the settable attributes for this cookbook.

Note that all attributes are in the ``default['openstack']`` "namespace"

The usage of attributes to generate the ``ceilometer.conf`` and
``gnocchi`` is described in the openstack-common cookbook.

Recipes
=======

agent-central
-------------

- Installs agent central service.

agent-compute
-------------

- Installs agent compute service.

agent-notification
------------------

- Installs agent notification service.

aodh
----

- Installs aodh service

common
------

- Common metering configuration.

gnocchi_configure
-----------------

- Configure Gnocchi

gnocchi_install
---------------

- Installs and starts the Gnocchi service

identity_registration
---------------------

-  Registers the endpoints, tenant and user for metering and metric
   service with Keystone.

setup
-----

- Run database migrations

License and Author
==================

+-----------------+--------------------------------------------+
| **Author**      | Matt Ray (matt@opscode.com)                |
+-----------------+--------------------------------------------+
| **Author**      | John Dewey (jdewey@att.com)                |
+-----------------+--------------------------------------------+
| **Author**      | Justin Shepherd (jshepher@rackspace.com)   |
+-----------------+--------------------------------------------+
| **Author**      | Salman Baset (sabaset@us.ibm.com)          |
+-----------------+--------------------------------------------+
| **Author**      | Ionut Artarisi (iartarisi@suse.cz)         |
+-----------------+--------------------------------------------+
| **Author**      | Eric Zhou (zyouzhou@cn.ibm.com)            |
+-----------------+--------------------------------------------+
| **Author**      | Chen Zhiwei (zhiwchen@cn.ibm.com)          |
+-----------------+--------------------------------------------+
| **Author**      | David Geng (gengjh@cn.ibm.com)             |
+-----------------+--------------------------------------------+
| **Author**      | Mark Vanderwiel (vanderwl@us.ibm.com)      |
+-----------------+--------------------------------------------+
| **Author**      | Jan Klare (j.klare@cloudbau.de)            |
+-----------------+--------------------------------------------+
| **Author**      | Christoph Albers (c.albers@x-ion.de)       |
+-----------------+--------------------------------------------+
| **Author**      | Lance Albertson (lance@osuosl.org          |
+-----------------+--------------------------------------------+

+-----------------+---------------------------------------------+
| **Copyright**   | Copyright (c) 2013, Opscode, Inc.           |
+-----------------+---------------------------------------------+
| **Copyright**   | Copyright (c) 2013, AT&T Services, Inc.     |
+-----------------+---------------------------------------------+
| **Copyright**   | Copyright (c) 2013, Rackspace US, Inc.      |
+-----------------+---------------------------------------------+
| **Copyright**   | Copyright (c) 2013-2014, IBM, Corp.         |
+-----------------+---------------------------------------------+
| **Copyright**   | Copyright (c) 2013-2014, SUSE Linux GmbH    |
+-----------------+---------------------------------------------+
| **Copyright**   | Copyright (c) 2019, Oregon State University |
+-----------------+---------------------------------------------+

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

::

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
