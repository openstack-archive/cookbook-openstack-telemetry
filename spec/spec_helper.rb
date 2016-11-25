# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-telemetry' }

require 'chef/application'

LOG_LEVEL = :fatal
REDHAT_OPTS = {
  platform: 'redhat',
  version: '7.1',
  log_level: ::LOG_LEVEL
}.freeze
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '14.04',
  log_level: ::LOG_LEVEL
}.freeze

shared_context 'telemetry-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return '1.1.1.1:5672,2.2.2.2:5672'
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers).and_return([])
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'ceilometer')
      .and_return('ceilometer-dbpass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'gnocchi')
      .and_return('gnocchi-dbpass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-telemetry')
      .and_return('ceilometer-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-telemetry-metric')
      .and_return('gnocchi-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin-pass')
    allow(Chef::Application).to receive(:fatal!)
    node.set['openstack']['telemetry']['conf']['api']['host'] = '127.0.0.1'
    node.set['openstack']['telemetry']['conf']['api']['port'] = '8777'
    node.set['openstack']['telemetry-metric']['conf']['api']['host'] = '127.0.0.1'
    node.set['openstack']['telemetry-metric']['conf']['api']['port'] = '8041'
    stub_command('/usr/sbin/apache2 -t')
    stub_command('/usr/sbin/httpd -t')
  end
end

shared_examples 'expect-runs-common-recipe' do
  it 'runs common recipe' do
    expect(chef_run).to include_recipe 'openstack-telemetry::common'
  end
end
