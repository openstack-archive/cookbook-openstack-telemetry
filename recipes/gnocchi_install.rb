#
# Cookbook:: openstack-telemetry
# Recipe:: gnocchi_install
#
# Copyright:: 2020, Oregon State University
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
package platform['gnocchi_packages'] do
  options platform['package_overrides']
  action :upgrade
end

# stop and disable the service gnocchi-api_service itself, since it should be run inside
# of apache
service platform['gnocchi-api_service'] do
  action [:stop, :disable]
end
