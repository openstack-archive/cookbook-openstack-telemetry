# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-telemetry' }

require 'chef/application'

LOG_LEVEL = :fatal
SUSE_OPTS = {
  platform: 'suse',
  version: '11.03',
  log_level: ::LOG_LEVEL
}
REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.3',
  log_level: ::LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: ::LOG_LEVEL
}

shared_context 'telemetry-stubs' do
  before do
    Chef::Recipe.any_instance.stub(:memcached_servers).and_return([])
    Chef::Recipe.any_instance.stub(:get_password)
      .with('db', anything)
      .and_return('')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'openstack-ceilometer')
      .and_return('ceilometer-pass')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    Chef::Recipe.any_instance.stub(:get_secret)
      .with('openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    Chef::Recipe.any_instance.stub(:get_secret)
      .with('openstack_metering_secret')
      .and_return('metering_secret')
    Chef::Application.stub(:fatal!)
  end
end

shared_examples 'expect-runs-common-recipe' do
  it 'runs common recipe' do
    expect(chef_run).to include_recipe 'openstack-telemetry::common'
  end
end
