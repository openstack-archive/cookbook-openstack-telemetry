openstack-telemetry Cookbook CHANGELG
==============================
This file is used to list changes made in each version of the openstack-metering cookbook.
## 9.1.1
* Remove policy.json file, it's just a dup of what's in the package

## 9.1.0
### Blue print
# Add recipes for the ceilometer alarm services (alarm-services)
# Add recipes for the ceilometer agent notification service (alarm-services)

## 9.0.0
* Upgrade to Icehouse

## 8.4.0
### Blue print
# Use the library method auth_uri_transform

## 8.3.0
* Rename openstack-metering to openstack-telemetry

## 8.2.0
### Blueprint
* Add NoSQL support for metering.

## 8.1.0
* Add client recipe

## 8.0.0
### New version
* Upgrade to upstream Havana release

## 7.1.1
### Bug
* Relax the dependency on openstack-identity to the 7.x series

## 7.1.0
### Blueprint
* Added qpid support to ceilometer. default is rabbitmq

## 7.0.5
### Bug
* Corrected inconsistent keystone middleware auth_token for ceilometer.conf.erb.

## 7.0.4
### Bug
* Ubuntu package dependency for python-mysqldb missing for ceilometer-collector

## 7.0.3
### Bug
* Ubuntu cloud archive dpkg failing to install init script properly for agent-compute

## 7.0.2
### Improvement
* Add optional host to the ceilometer.conf

## 7.0.1
### Bug
* Fix naming inconsistency for db password databag. This makes the metering cookbook consistent with all the others.
