#
# Cookbook:: openstack-telemetry
# Recipe:: agent-central
#
# Copyright:: 2013-2021, AT&T Services, Inc.
# Copyright:: 2013-2021, SUSE Linux GmbH
# Copyright:: 2019-2021, Oregon State University
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
package platform['agent_central_packages'] do
  options platform['package_overrides']
  action :upgrade
end

service 'ceilometer-agent-central' do
  service_name platform['agent_central_service']
  subscribes :restart, "template[#{node['openstack']['telemetry']['conf_file']}]"
  subscribes :restart, "template[#{::File.join(node['openstack']['telemetry']['conf_dir'], 'pipeline.yaml')}]"
  subscribes :restart, "template[#{::File.join(node['openstack']['telemetry']['conf_dir'], 'polling.yaml')}]"
  action [:enable, :start]
end
