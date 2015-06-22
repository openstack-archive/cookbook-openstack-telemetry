# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-telemetry' }

require 'chef/application'

LOG_LEVEL = :fatal
SUSE_OPTS = {
  platform: 'suse',
  version: '11.3',
  log_level: ::LOG_LEVEL
}
REDHAT_OPTS = {
  platform: 'redhat',
  version: '7.1',
  log_level: ::LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '14.04',
  log_level: ::LOG_LEVEL
}

shared_context 'telemetry-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return '1.1.1.1:5672,2.2.2.2:5672'
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers).and_return([])
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-ceilometer')
      .and_return('ceilometer-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_metering_secret')
      .and_return('metering_secret')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow(Chef::Application).to receive(:fatal!)
  end
end

shared_examples 'expect-runs-common-recipe' do
  it 'runs common recipe' do
    expect(chef_run).to include_recipe 'openstack-telemetry::common'
  end
end
