# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: default
#
# Copyright 2013, AT&T Services, Inc.
# Copyright 2013, SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# The name of the Chef role that knows about the message queue server
# that Nova uses
default['openstack']['telemetry']['rabbit_server_chef_role'] = 'os-ops-messaging'

default['openstack']['telemetry']['conf_dir'] = '/etc/ceilometer'
default['openstack']['telemetry']['conf'] = ::File.join(node['openstack']['telemetry']['conf_dir'], 'ceilometer.conf')
default['openstack']['telemetry']['periodic_interval'] = 600
default['openstack']['telemetry']['syslog']['use'] = false
default['openstack']['telemetry']['verbose'] = 'true'
default['openstack']['telemetry']['debug'] = 'false'

default['openstack']['telemetry']['api']['auth']['cache_dir'] = '/var/cache/ceilometer/api'

default['openstack']['telemetry']['api']['auth']['version'] = node['openstack']['api']['auth']['version']

default['openstack']['telemetry']['user'] = 'ceilometer'
default['openstack']['telemetry']['group'] = 'ceilometer'

default['openstack']['telemetry']['region'] = node['openstack']['region']
default['openstack']['telemetry']['service_user'] = 'ceilometer'
default['openstack']['telemetry']['service_tenant_name'] = 'service'
default['openstack']['telemetry']['service_role'] = 'admin'

case node['openstack']['compute']['driver']
when 'libvirt.LibvirtDriver'
  default['openstack']['telemetry']['hypervisor_inspector'] = 'libvirt'
else
  default['openstack']['telemetry']['hypervisor_inspector'] = nil
end

case platform_family
when 'suse' # :pragma-foodcritic: ~FC024 - won't fix this
  default['openstack']['telemetry']['platform'] = {
    'mysql_python_packages' => ['python-mysql'],
    'postgresql_python_packages' => ['python-psycopg2'],
    'common_packages' => ['openstack-ceilometer'],
    'agent_central_packages' => ['openstack-ceilometer-agent-central'],
    'agent_central_service' => 'openstack-ceilometer-agent-central',
    'agent_compute_packages' => ['openstack-ceilometer-agent-compute'],
    'agent_compute_service' => 'openstack-ceilometer-agent-compute',
    'agent_notification_packages' => ['openstack-ceilometer-agent-notification'],
    'agent_notification_service' => 'openstack-ceilometer-agent-notification',
    'alarm_evaluator_packages' => ['openstack-ceilometer-alarm-evaluator'],
    'alarm_evaluator_service' => 'openstack-ceilometer-alarm-evaluator',
    'alarm_notifier_packages' => ['openstack-ceilometer-alarm-notifier'],
    'alarm_notifier_service' => 'openstack-ceilometer-alarm-notifier',
    'api_packages' => ['openstack-ceilometer-api'],
    'api_service' => 'openstack-ceilometer-api',
    'client_packages' => ['python-ceilometerclient'],
    'collector_packages' => ['openstack-ceilometer-collector'],
    'collector_service' => 'openstack-ceilometer-collector',
    'package_overrides' => ''
  }

when 'fedora', 'rhel'
  default['openstack']['telemetry']['platform'] = {
    'mysql_python_packages' => ['MySQL-python'],
    'db2_python_packages' => ['python-ibm-db', 'python-ibm-db-sa'],
    'postgresql_python_packages' => ['python-psycopg2'],
    'common_packages' => ['openstack-ceilometer-common'],
    'agent_central_packages' => ['openstack-ceilometer-central'],
    'agent_central_service' => 'openstack-ceilometer-central',
    'agent_compute_packages' => ['openstack-ceilometer-compute'],
    'agent_compute_service' => 'openstack-ceilometer-compute',
    'agent_notification_packages' => ['openstack-ceilometer-collector'],
    'agent_notification_service' => 'openstack-ceilometer-notification',
    'alarm_evaluator_packages' => ['openstack-ceilometer-alarm'],
    'alarm_evaluator_service' => 'openstack-ceilometer-alarm-evaluator',
    'alarm_notifier_packages' => ['openstack-ceilometer-alarm'],
    'alarm_notifier_service' => 'openstack-ceilometer-alarm-notifier',
    'api_packages' => ['openstack-ceilometer-api'],
    'api_service' => 'openstack-ceilometer-api',
    'client_packages' => ['python-ceilometerclient'],
    'collector_packages' => ['openstack-ceilometer-collector'],
    'collector_service' => 'openstack-ceilometer-collector',
    'package_overrides' => ''
  }

when 'debian'
  default['openstack']['telemetry']['platform'] = {
    'mysql_python_packages' => ['python-mysqldb'],
    'postgresql_python_packages' => ['python-psycopg2'],
    'common_packages' => ['ceilometer-common'],
    'agent_central_packages' => ['ceilometer-agent-central'],
    'agent_central_service' => 'ceilometer-agent-central',
    'agent_compute_packages' => ['ceilometer-agent-compute'],
    'agent_compute_service' => 'ceilometer-agent-compute',
    'agent_notification_packages' => ['ceilometer-agent-notification'],
    'agent_notification_service' => 'ceilometer-agent-notification',
    'alarm_evaluator_packages' => ['ceilometer-alarm-evaluator'],
    'alarm_evaluator_service' => 'ceilometer-alarm-evaluator',
    'alarm_notifier_packages' => ['ceilometer-alarm-notifier'],
    'alarm_notifier_service' => 'ceilometer-alarm-notifier',
    'api_packages' => ['ceilometer-api'],
    'api_service' => 'ceilometer-api',
    'client_packages' => ['python-ceilometerclient'],
    'collector_packages' => ['ceilometer-collector', 'python-mysqldb'],
    'collector_service' => 'ceilometer-collector',
    'package_overrides' => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
