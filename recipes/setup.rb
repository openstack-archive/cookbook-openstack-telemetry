# encoding: UTF-8
#
# Cookbook Name:: openstack-telemetry
# Recipe:: common
#
# Copyright 2019, Oregon State University
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

class ::Chef::Recipe
  include ::Openstack
end

conf_switch = "--config-file #{node['openstack']['telemetry']['conf_file']}"
execute 'ceilometer database migration' do
  command "ceilometer-upgrade #{node['openstack']['telemetry']['upgrade_opts']} #{conf_switch}"
end
