# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

::LOG_LEVEL = :fatal
::SUSE_OPTS = {
  platform: 'suse',
  version: '11.03',
  log_level: ::LOG_LEVEL
}
::REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.3',
  log_level: ::LOG_LEVEL
}
::UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: ::LOG_LEVEL
}

# TODO(chrislaco): Factor this into proper RSpec shared_contexts
def metering_stubs # rubocop:disable MethodLength
  ::Chef::Recipe.any_instance.stub(:memcached_servers).and_return([])
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('db', anything)
    .and_return('')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('service', anything)
    .and_return('')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('user', 'guest')
    .and_return('mq-pass')
  ::Chef::Recipe.any_instance.stub(:secret)
    .with('secrets', 'openstack_identity_bootstrap_token')
    .and_return('bootstrap-token')
  ::Chef::Application.stub(:fatal!)
end

def expect_runs_common_recipe
  it 'runs common recipe' do
    expect(@chef_run).to include_recipe 'openstack-metering::common'
  end
end

# README(galstrom21): This will remove any coverage warnings from
#   dependent cookbooks
ChefSpec::Coverage.filters << '*/openstack-metering'

at_exit { ChefSpec::Coverage.report! }
