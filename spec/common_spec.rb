# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    context 'with logging enabled' do
      before do
        node.set['openstack']['telemetry']['syslog']['use'] = true
      end

      it 'runs logging recipe' do
        expect(chef_run).to include_recipe 'openstack-common::logging'
      end
    end

    it 'installs the common package' do
      expect(chef_run).to install_package 'ceilometer-common'
    end

    describe '/etc/ceilometer' do
      let(:dir) { chef_run.directory('/etc/ceilometer') }

      it 'creates the /etc/ceilometer directory' do
        expect(chef_run).to create_directory(dir.name).with(
          user: 'ceilometer',
          group: 'ceilometer',
          mode: 0750
          )
      end
    end

    describe 'ceilometer.conf' do
      let(:file) { chef_run.template('/etc/ceilometer/ceilometer.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'ceilometer',
          group: 'ceilometer',
          mode: 0640
          )
      end

      context 'rabbit mq backend' do
        before do
          node.set['openstack']['mq']['telemetry']['service_type'] = 'rabbitmq'
        end

        it 'has default rabbit_* options set' do
          [
            /^rabbit_userid = guest$/,
            /^rabbit_password = mq-pass$/,
            /^rabbit_port = 5672$/,
            /^rabbit_host = 127.0.0.1$/,
            /^rabbit_virtual_host = \/$/,
            /^rabbit_use_ssl = false$/,
            %r{^auth_uri = http://127.0.0.1:5000/v2.0$},
            /^auth_host = 127.0.0.1$/,
            /^auth_port = 35357$/,
            /^auth_protocol = http$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end

      context 'qpid mq backend' do
        before do
          node.set['openstack']['mq']['telemetry']['service_type'] = 'qpid'
          node.set['openstack']['mq']['telemetry']['qpid']['username'] = 'guest'
        end

        it 'has default qpid_* options set' do
          [
            /^qpid_hostname=127.0.0.1$/,
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
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end

      context 'has keystone authtoken configuration' do
        it 'has auth_uri' do
          expect(chef_run).to render_file(file.name).with_content(
            /^#{Regexp.quote('auth_uri = http://127.0.0.1:5000/v2.0')}$/)
        end

        it 'has auth_host' do
          expect(chef_run).to render_file(file.name).with_content(
            /^#{Regexp.quote('auth_host = 127.0.0.1')}$/)
        end

        it 'has auth_port' do
          expect(chef_run).to render_file(file.name).with_content(
            /^auth_port = 35357$/)
        end

        it 'has auth_protocol' do
          expect(chef_run).to render_file(file.name).with_content(
            /^auth_protocol = http$/)
        end

        it 'has no auth_version' do
          expect(chef_run).not_to render_file(file.name).with_content(
            /^auth_version = v2.0$/)
        end

        it 'has admin_tenant_name' do
          expect(chef_run).to render_file(file.name).with_content(
            /^admin_tenant_name = service$/)
        end

        it 'has admin_user' do
          expect(chef_run).to render_file(file.name).with_content(
            /^admin_user = ceilometer$/)
        end

        it 'has admin_password' do
          expect(chef_run).to render_file(file.name).with_content(
            /^admin_password = ceilometer-pass$/)
        end

        it 'has signing_dir' do
          expect(chef_run).to render_file(file.name).with_content(
            /^#{Regexp.quote('signing_dir = /var/cache/ceilometer/api')}$/)
        end
      end

      it 'has metering secret' do
        r = /^metering_secret = metering_secret$/
        expect(chef_run).to render_file(file.name).with_content(r)
      end
    end

    describe 'policy.json' do
      let(:file) { chef_run.cookbook_file('/etc/ceilometer/policy.json') }

      it 'installs the /etc/ceilometer/policy.json file' do
        expect(chef_run).to create_cookbook_file(file.name).with(
          user: 'ceilometer',
          group: 'ceilometer',
          mode: 0640
          )
      end
    end
  end
end
