openstack-metering Cookbook CHANGELOG
==============================
This file is used to list changes made in each version of the openstack-metering cookbook.

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
