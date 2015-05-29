# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: agent-compute
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

include_recipe 'openstack-telemetry::common'

platform = node['openstack']['telemetry']['platform']
platform['agent_compute_packages'].each do |pkg|
  package pkg do
    options platform['package_overrides']
    action :upgrade
  end
end

# temp fix for compute-agent init not installing properly ubuntu
# See https://bugs.launchpad.net/cloud-archive/+bug/1221945
if node['platform'] == 'ubuntu'
  init_script = '/etc/init/ceilometer-agent-compute.conf'
  execute 'fix init script' do
    command "cp #{init_script}.dpkg-new #{init_script}"
    not_if { ::File.exist?(init_script) }
  end
end

service 'ceilometer-agent-compute' do
  service_name platform['agent_compute_service']
  supports status: true, restart: true
  subscribes :restart, "template[#{node['openstack']['telemetry']['conf']}]"

  action [:enable, :start]
end
