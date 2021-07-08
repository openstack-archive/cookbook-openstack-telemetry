require_relative 'spec_helper'

describe 'openstack-telemetry::aodh' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs aodh packages' do
      expect(chef_run).to upgrade_package %w(aodh-api aodh-evaluator aodh-expirer aodh-listener aodh-notifier python3-ceilometerclient)
    end

    it do
      expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:8042))
    end

    it do
      expect(chef_run).to enable_apache2_module('wsgi')
    end

    it do
      expect(chef_run).to_not enable_apache2_module('ssl')
    end

    describe 'aodh.conf' do
      let(:file) { chef_run.template('/etc/aodh/aodh.conf') }

      it do
        expect(chef_run).to create_directory('/etc/aodh')
      end

      it do
        expect(chef_run).to create_template(file.name).with(
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          user: 'aodh',
          group: 'aodh',
          mode: '640',
          sensitive: true,
          variables: {
            service_config: {
              'DEFAULT' => {
                'transport_url' => 'rabbit://guest:mypass@127.0.0.1:5672' },
              'api' => {
                'host' => '127.0.0.1',
                'port' => 8042,
              },
              'database' => {
                'connection' => 'mysql+pymysql://aodh:aodh-dbpass@127.0.0.1:3306/aodh?charset=utf8' },
              'keystone_authtoken' => {
                'auth_type' => 'v3password',
                'auth_url' => 'http://127.0.0.1:5000/v3',
                'memcache_servers' => '',
                'password' => 'aodh-pass',
                'project_domain_name' => 'Default',
                'project_name' => 'service',
                'region_name' => 'RegionOne',
                'user_domain_name' => 'Default',
                'username' => 'aodh',
              },
              'service_credentials' => {
                'auth_type' => 'v3password',
                'auth_url' => 'http://127.0.0.1:5000/v3',
                'interface' => 'internal',
                'password' => 'aodh-pass',
                'project_domain_name' => 'Default',
                'project_name' => 'service',
                'region_name' => 'RegionOne',
                'user_domain_name' => 'Default',
                'username' => 'aodh',
              },
            },
          }
        )
      end

      it do
        [
          /^username = aodh$/,
          /^user_domain_name = Default$/,
          /^project_name = service$/,
          /^project_domain_name = Default$/,
          /^auth_type = v3password$/,
          /^region_name = RegionOne$/,
          %r{auth_url = http://127\.0\.0\.1:5000/v3},
          /^password = aodh-pass$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', line)
        end
      end

      it do
        [
          /^host = 127\.0\.0\.1$/,
          /^port = 8042$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('api', line)
        end
      end

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'database',
            %(connection = mysql+pymysql://aodh:aodh-dbpass@127.0.0.1:3306/aodh?charset=utf8)
          )
      end
    end

    it do
      expect(chef_run).to run_execute('run aodh-dbsync')
        .with(
          command: 'aodh-dbsync ',
          user: 'aodh'
        )
    end

    it 'creates directory /var/www/html/aodh' do
      expect(chef_run).to create_directory('/var/www/html/aodh').with(
        user: 'root',
        group: 'root',
        mode: '755'
      )
    end

    it 'creates wsgi file' do
      expect(chef_run).to create_file('/var/www/html/aodh/app').with(
        user: 'root',
        group: 'root',
        mode: '755'
      )
    end

    describe 'apache wsgi' do
      file = '/etc/apache2/sites-available/aodh-api.conf'
      it "creates #{file}" do
        expect(chef_run).to create_template(file).with(
          source: 'wsgi-template.conf.erb',
          variables: {
            ca_certs_path: '/etc/ceilometer/ssl/certs/',
            cert_file: '/etc/ceilometer/ssl/certs/sslcert.pem',
            cert_required: false,
            chain_file: nil,
            ciphers: nil,
            daemon_process: 'aodh-api',
            group: 'aodh',
            key_file: '/etc/ceilometer/ssl/private/sslkey.pem',
            log_dir: '/var/log/apache2',
            protocol: 'All -SSLv2 -SSLv3',
            run_dir: '/var/lock',
            server_entry: '/var/www/html/aodh/app',
            server_host: '127.0.0.1',
            server_port: 8042,
            user: 'aodh',
            use_ssl: false,
          }
        )
      end

      context "configures #{file} common lines" do
        cached(:chef_run) do
          node.override['openstack']['telemetry_metric']['custom_template_banner'] = 'custom_template_banner_value'
          runner.converge(described_recipe)
        end
        [
          /^<VirtualHost 127.0.0.1:8042>$/,
          /WSGIDaemonProcess aodh-api processes=2 threads=10 user=aodh group=aodh display-name=%{GROUP}$/,
          /WSGIProcessGroup aodh-api$/,
          %r{WSGIScriptAlias / /var/www/html/aodh/app$},
          %r{^WSGISocketPrefix /var/lock$},
          %r{ErrorLog /var/log/apache2/aodh-api_error.log$},
          %r{CustomLog /var/log/apache2/aodh-api_access.log combined$},
        ].each do |line|
          it do
            expect(chef_run).to render_file(file).with_content(line)
          end
        end
      end

      it "does not configure #{file} triggered common lines" do
        [
          /LogLevel/,
          /SSL/,
        ].each do |line|
          expect(chef_run).not_to render_file(file).with_content(line)
        end
      end
      context 'Enable SSL' do
        cached(:chef_run) do
          node.override['openstack']['aodh']['ssl']['enabled'] = true
          runner.converge(described_recipe)
        end

        it do
          expect(chef_run).to enable_apache2_module('ssl')
        end

        it "configures #{file} common ssl lines" do
          [
            /SSLEngine On$/,
            %r{SSLCertificateFile /etc/ceilometer/ssl/certs/sslcert.pem$},
            %r{SSLCertificateKeyFile /etc/ceilometer/ssl/private/sslkey.pem$},
            %r{SSLCACertificatePath /etc/ceilometer/ssl/certs/$},
            /SSLProtocol All -SSLv2 -SSLv3$/,
          ].each do |line|
            expect(chef_run).to render_file(file).with_content(line)
          end
        end
        it "does not configure #{file} common ssl lines" do
          [
            /SSLCertificateChainFile/,
            /SSLCipherSuite/,
            /SSLVerifyClient require/,
          ].each do |line|
            expect(chef_run).not_to render_file(file).with_content(line)
          end
        end
        context 'Enable chainfile, ciphers, cert_required' do
          cached(:chef_run) do
            node.override['openstack']['aodh']['ssl']['enabled'] = true
            node.override['openstack']['aodh']['ssl']['chainfile'] =
              '/etc/ceilometer/ssl/certs/chainfile.pem'
            node.override['openstack']['aodh']['ssl']['ciphers'] = 'ciphers_value'
            node.override['openstack']['aodh']['ssl']['cert_required'] = true
            runner.converge(described_recipe)
          end
          it "configures #{file} chainfile when set" do
            expect(chef_run).to render_file(file)
              .with_content(%r{SSLCertificateChainFile /etc/ceilometer/ssl/certs/chainfile.pem$})
          end
          it "configures #{file} ciphers when set" do
            expect(chef_run).to render_file(file)
              .with_content(/SSLCipherSuite ciphers_value$/)
          end
          it "configures #{file} cert_required set" do
            expect(chef_run).to render_file(file)
              .with_content(/SSLVerifyClient require$/)
          end
        end
      end

      describe 'restart apache' do
        it do
          expect(chef_run.template('/etc/apache2/sites-available/aodh-api.conf')).to \
            notify('service[apache2]').to(:restart)
        end
        it do
          expect(chef_run.apache2_site('aodh-api')).to notify('service[apache2]').to(:restart).immediately
        end
      end
      %w(
        aodh-evaluator
        aodh-notifier
        aodh-listener
      ).each do |aodh_service|
        it do
          expect(chef_run).to start_service(aodh_service).with(service_name: aodh_service)
          expect(chef_run).to enable_service(aodh_service).with(service_name: aodh_service)
        end
        it do
          expect(chef_run.service(aodh_service)).to subscribe_to('template[/etc/aodh/aodh.conf]')
        end
      end
    end
  end
end
