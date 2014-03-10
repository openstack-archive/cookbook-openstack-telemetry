# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-metering::common' do
  before { metering_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS) do |n|
        n.set['openstack']['metering']['syslog']['use'] = true
      end
      @chef_run.converge 'openstack-metering::common'
    end

    it 'runs logging recipe' do
      expect(@chef_run).to include_recipe 'openstack-common::logging'
    end

    it 'installs the common package' do
      expect(@chef_run).to install_package 'ceilometer-common'
    end

    it 'creates the /etc/ceilometer directory' do
      expect(@chef_run).to create_directory('/etc/ceilometer').with(
        user: 'ceilometer',
        group: 'ceilometer',
        mode: 0750
        )
    end

    describe '/etc/ceilometer' do
      before do
        @filename = '/etc/ceilometer/ceilometer.conf'
      end

      it 'creates the file' do
        expect(@chef_run).to create_template(@filename).with(
          user: 'ceilometer',
          group: 'ceilometer',
          mode: 0640
          )
      end

      context 'with rabbitmq default' do
        [/^rabbit_userid = guest$/,
         /^rabbit_password = mq-pass$/,
         /^rabbit_port = 5672$/,
         /^rabbit_host = 127.0.0.1$/,
         /^rabbit_virtual_host = \/$/,
         /^rabbit_use_ssl = false$/,
         %r{^auth_uri = http://127.0.0.1:5000/v2.0$},
         /^auth_host = 127.0.0.1$/,
         /^auth_port = 35357$/,
         /^auth_protocol = http$/
        ].each do |content|
          it 'has a \#{content.source[1...-1]}\' line' do
            expect(@chef_run).to render_file(@filename).with_content(content)
          end
        end
      end

      context 'with qpid enabled' do
        before do
          @chef_run.node.set['openstack']['mq']['metering']['service_type'] = 'qpid'
          @chef_run.node.set['openstack']['mq']['metering']['qpid']['username'] = 'guest'
          @chef_run.converge 'openstack-metering::common'
        end

        [/^qpid_hostname=127.0.0.1$/,
         /^qpid_port=5672$/,
         /^qpid_username=guest$/,
         /^qpid_password=mq-pass$/,
         /^qpid_sasl_mechanisms=$/,
         /^qpid_reconnect=true$/,
         /^qpid_reconnect_timeout=0$/,
         /^qpid_reconnect_limit=0$/,
         /^qpid_reconnect_interval_min=0$/,
         /^qpid_reconnect_interval_max=0$/,
         /^qpid_reconnect_interval_max=0$/,
         /^qpid_reconnect_interval=0$/,
         /^qpid_heartbeat=60$/,
         /^qpid_protocol=tcp$/,
         /^qpid_tcp_nodelay=true$/
        ].each do |content|
          it 'has a \#{content.source[1...-1]}\' line' do
            expect(@chef_run).to render_file(@filename).with_content(content)
          end
        end
      end
    end

    it 'installs the /etc/ceilometer/policy.json file' do
      expect(@chef_run).to create_cookbook_file('/etc/ceilometer/policy.json').with(
        user: 'ceilometer',
        group: 'ceilometer',
        mode: 0640
        )
    end
  end
end
