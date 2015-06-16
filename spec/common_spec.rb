# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
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

    it 'installs mysql python packages by default' do
      expect(chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'installs postgresql python packages if explicitly told' do
      node.set['openstack']['db']['telemetry']['service_type'] = 'postgresql'
      expect(chef_run).to upgrade_package 'python-psycopg2'
    end

    it 'installs the common package' do
      expect(chef_run).to upgrade_package 'ceilometer-common'
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

      it 'has default values' do
        node.set['openstack']['telemetry']['syslog']['use'] = true
        [%r{^os_auth_url = http://127.0.0.1:5000/v2.0$},
         /^os_tenant_name = service$/,
         /^os_password = ceilometer-pass$/,
         /^os_username = ceilometer$/,
         /^verbose = true$/,
         /^debug = false$/,
         %r{^log_config = /etc/openstack/logging.conf$},
         /^glance_registry_host = 127.0.0.1$/,
         /^periodic_interval = 600$/].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'has default sample_source set' do
        expect(chef_run).to render_file(file.name).with_content(
          /^sample_source = openstack$/)
      end

      it 'has default os_region_name set' do
        expect(chef_run).to render_file(file.name).with_content(
          /^os_region_name = RegionOne$/)
      end

      it 'has sample_source set' do
        node.set['openstack']['telemetry']['sample_source'] = 'RegionOne'
        expect(chef_run).to render_file(file.name).with_content(
          /^sample_source = RegionOne$/)
      end

      context 'rabbit mq backend' do
        before do
          node.set['openstack']['mq']['telemetry']['service_type'] = 'rabbitmq'
        end

        it 'has default RPC/AMQP options set' do
          [/^amqp_durable_queues=false$/,
           /^amqp_auto_delete=false$/,
           /^heartbeat_timeout_threshold=0$/,
           /^heartbeat_rate=2$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end

        describe 'ha rabbit disabled' do
          before do
            node.override['openstack']['mq']['telemetry']['rabbit']['ha'] = false
          end

          it 'has default rabbit_* options set' do
            [
              /^rabbit_userid = guest$/,
              /^rabbit_password = mq-pass$/,
              /^rabbit_port = 5672$/,
              /^rabbit_host = 127.0.0.1$/,
              /^rabbit_virtual_host = \/$/,
              /^rabbit_max_retries = 0$/,
              /^rabbit_retry_interval = 1$/
            ].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          it 'does not have ha rabbit options set' do
            [/^rabbit_hosts = /,
             /^rabbit_ha_queues = /].each do |line|
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end
        end

        describe 'ha rabbit enabled' do
          before do
            node.override['openstack']['mq']['telemetry']['rabbit']['ha'] = true
          end

          it 'sets ha rabbit options correctly' do
            [
              /^rabbit_userid = guest$/,
              /^rabbit_password = mq-pass$/,
              /^rabbit_hosts = 1.1.1.1:5672,2.2.2.2:5672$/,
              /^rabbit_ha_queues = True$/,
              /^rabbit_virtual_host = \/$/
            ].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          it 'does not have non-ha rabbit options set' do
            [/^rabbit_host = /,
             /^rabbit_port = /].each do |line|
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end
        end

        it 'does not have ssl config set' do
          [/^rabbit_use_ssl=/,
           /^kombu_ssl_version=/,
           /^kombu_ssl_keyfile=/,
           /^kombu_ssl_certfile=/,
           /^kombu_ssl_ca_certs=/,
           /^kombu_reconnect_delay=/,
           /^kombu_reconnect_timeout=/].each do |line|
            expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end

        it 'sets ssl config' do
          node.set['openstack']['mq']['telemetry']['rabbit']['use_ssl'] = true
          node.set['openstack']['mq']['telemetry']['rabbit']['kombu_ssl_version'] = 'TLSv1.2'
          node.set['openstack']['mq']['telemetry']['rabbit']['kombu_ssl_keyfile'] = 'keyfile'
          node.set['openstack']['mq']['telemetry']['rabbit']['kombu_ssl_certfile'] = 'certfile'
          node.set['openstack']['mq']['telemetry']['rabbit']['kombu_ssl_ca_certs'] = 'certsfile'
          node.set['openstack']['mq']['telemetry']['rabbit']['kombu_reconnect_delay'] = 123.123
          node.set['openstack']['mq']['telemetry']['rabbit']['kombu_reconnect_timeout'] = 123
          [/^rabbit_use_ssl=true/,
           /^kombu_ssl_version=TLSv1.2$/,
           /^kombu_ssl_keyfile=keyfile$/,
           /^kombu_ssl_certfile=certfile$/,
           /^kombu_ssl_ca_certs=certsfile$/,
           /^kombu_reconnect_delay=123.123$/,
           /^kombu_reconnect_timeout=123$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end
      end

      context 'qpid mq backend' do
        before do
          node.set['openstack']['mq']['telemetry']['service_type'] = 'qpid'
          node.set['openstack']['mq']['telemetry']['qpid']['username'] = 'guest'
        end

        it 'has default RPC/AMQP options set' do
          [/^amqp_durable_queues=false$/,
           /^amqp_auto_delete=false$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', line)
          end
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
            /^qpid_tcp_nodelay=true$/,
            /^qpid_topology_version=1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', line)
          end
        end
      end

      context 'database' do
        it 'has connection set' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('database', /^#{Regexp.quote('connection=mysql://ceilometer:@127.0.0.1:3306/ceilometer?charset=utf8')}$/)
        end

        it 'has time_to_live set' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('database', /^time_to_live=1800$/)
        end
      end

      context 'service_credentials attributes with default values' do
        it 'sets cafile' do
          expect(chef_run).not_to render_file(file.name).with_content(/^os_cacert = $/)
        end

        it 'sets insecure' do
          expect(chef_run).to render_file(file.name).with_content(/^insecure = false$/)
        end
      end

      context 'service_credentials attributes' do
        it 'sets cafile' do
          node.set['openstack']['telemetry']['service-credentials']['cafile'] = 'dir/to/path'
          expect(chef_run).to render_file(file.name).with_content(%r{^os_cacert = dir/to/path$})
        end

        it 'sets insecure' do
          node.set['openstack']['telemetry']['service-credentials']['insecure'] = true
          expect(chef_run).to render_file(file.name).with_content(/^insecure = true$/)
        end
      end

      context 'keystone authtoken attributes with default values' do
        it 'sets memcached server(s)' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcached_servers = $/)
        end

        it 'sets memcache security strategy' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcache_security_strategy = $/)
        end

        it 'sets memcache secret key' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcache_secret_key = $/)
        end

        it 'sets cafile' do
          expect(chef_run).not_to render_file(file.name).with_content(/^cafile = $/)
        end

        it 'sets token hash algorithms' do
          expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = md5$/)
        end
      end

      context 'has keystone authtoken configuration' do
        it 'has auth_uri' do
          expect(chef_run).to render_file(file.name).with_content(
            /^#{Regexp.quote('auth_uri = http://127.0.0.1:5000/v2.0')}$/)
        end

        it 'has identity_uri' do
          expect(chef_run).to render_file(file.name).with_content(
            /^#{Regexp.quote('identity_uri = http://127.0.0.1:35357/')}$/)
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

        it 'sets memcached server(s)' do
          node.set['openstack']['telemetry']['api']['auth']['memcached_servers'] = 'localhost:11211'
          expect(chef_run).to render_file(file.name).with_content(/^memcached_servers = localhost:11211$/)
        end

        it 'sets memcache security strategy' do
          node.set['openstack']['telemetry']['api']['auth']['memcache_security_strategy'] = 'MAC'
          expect(chef_run).to render_file(file.name).with_content(/^memcache_security_strategy = MAC$/)
        end

        it 'sets memcache secret key' do
          node.set['openstack']['telemetry']['api']['auth']['memcache_secret_key'] = '0123456789ABCDEF'
          expect(chef_run).to render_file(file.name).with_content(/^memcache_secret_key = 0123456789ABCDEF$/)
        end

        it 'sets cafile' do
          node.set['openstack']['telemetry']['api']['auth']['cafile'] = 'dir/to/path'
          expect(chef_run).to render_file(file.name).with_content(%r{^cafile = dir/to/path$})
        end

        it 'sets insecure' do
          node.set['openstack']['telemetry']['api']['auth']['insecure'] = true
          expect(chef_run).to render_file(file.name).with_content(/^insecure = true$/)
        end

        it 'sets token hash algorithm' do
          node.set['openstack']['telemetry']['api']['auth']['hash_algorithms'] = 'sha2'
          expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = sha2$/)
        end
      end

      it 'has metering secret' do
        r = /^metering_secret = metering_secret$/
        expect(chef_run).to render_file(file.name).with_content(r)
      end

      it 'has hypervisor inspector' do
        r = /^hypervisor_inspector = libvirt$/
        expect(chef_run).to render_file(file.name).with_content(r)
      end

      it 'has bind_host set' do
        node.set['openstack']['endpoints']['telemetry-api-bind']['host'] = '1.1.1.1'
        expect(chef_run).to render_file(file.name).with_content(
          /^host = 1.1.1.1$/)
      end

      it 'has bind_port set' do
        node.set['openstack']['endpoints']['telemetry-api-bind']['port'] = '9999'
        expect(chef_run).to render_file(file.name).with_content(/^port = 9999$/)
      end

      it 'has vmware section' do
        node.set['openstack']['compute']['driver'] = 'vmwareapi.VMwareVCDriver'
        [
          /^host_ip = $/,
          /^host_username = $/,
          /^host_password = vmware_secret_name$/,
          /^task_poll_interval = 0.5$/,
          /^api_retry_count = 10$/
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      context 'notification' do
        it 'has store_events option' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('notification', /^store_events = false$/)
        end
      end
    end
  end
end
