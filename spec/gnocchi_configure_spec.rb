require_relative 'spec_helper'

describe 'openstack-telemetry::gnocchi_configure' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it do
      expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:8041))
    end

    it do
      expect(chef_run).to create_apache2_mod_wsgi 'gnocchi'
    end

    it do
      expect(chef_run).to_not enable_apache2_module('ssl')
    end

    describe 'gnocchi.conf' do
      let(:file) { chef_run.template('/etc/gnocchi/gnocchi.conf') }

      it do
        expect(chef_run).to create_template(file.name).with(
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          user: 'gnocchi',
          group: 'gnocchi',
          mode: '640',
          sensitive: true
        )
      end

      it do
        [
          /^username = gnocchi$/,
          /^user_domain_name = Default$/,
          /^project_name = service$/,
          /^project_domain_name = Default$/,
          /^auth_type = v3password$/,
          /^region_name = RegionOne$/,
          %r{auth_url = http://127\.0\.0\.1:5000/v3},
          /^password = gnocchi-pass$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', line)
        end
      end

      it do
        [
          /^host = 127\.0\.0\.1$/,
          /^port = 8041$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('api', line)
        end
      end

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'database',
            %(connection = mysql+pymysql://gnocchi:gnocchi-dbpass@127.0.0.1:3306/gnocchi?charset=utf8)
          )
      end

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'indexer',
            %(url = mysql+pymysql://gnocchi:gnocchi-dbpass@127.0.0.1:3306/gnocchi?charset=utf8)
          )
      end
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/ceilometer/gnocchi_resources.yaml')
        .with(
          source: 'gnocchi_resources.yaml',
          owner: 'ceilometer',
          group: 'ceilometer',
          mode: '640'
        )
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/gnocchi/api-paste.ini')
        .with(
          source: 'api-paste.ini',
          owner: 'gnocchi',
          group: 'gnocchi',
          mode: '640'
        )
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/ceilometer/event_pipeline.yaml')
        .with(
          source: 'event_pipeline.yaml',
          owner: 'ceilometer',
          group: 'ceilometer',
          mode: '640'
        )
    end

    %w(tmp measure cache).each do |dir|
      describe "gnocchi #{dir} dir" do
        it 'file as storage backend' do
          expect(chef_run).to create_directory("/var/lib/gnocchi/#{dir}")
            .with(
              user: 'gnocchi',
              group: 'gnocchi',
              mode: '750'
            )
        end
        context 'other storage backend' do
          cached(:chef_run) do
            node.override['openstack']['telemetry_metric']['conf']['storage']['driver'] = 'ceph'
            runner.converge(described_recipe)
          end
          it do
            expect(chef_run).to_not create_directory("/var/lib/gnocchi/#{dir}")
              .with(
                user: 'gnocchi',
                group: 'gnocchi',
                mode: '750'
              )
          end
        end
      end
    end

    it do
      expect(chef_run).to run_execute('run gnocchi-upgrade')
        .with(
          command: 'gnocchi-upgrade ',
          user: 'gnocchi'
        )
    end

    it do
      expect(chef_run).to enable_service('gnocchi-metricd')
    end

    it do
      expect(chef_run).to start_service('gnocchi-metricd')
    end

    it 'creates directory /var/www/html/gnocchi' do
      expect(chef_run).to create_directory('/var/www/html/gnocchi').with(
        user: 'root',
        group: 'root',
        mode: '755'
      )
    end

    it 'creates wsgi file' do
      expect(chef_run).to create_file('/var/www/html/gnocchi/app').with(
        user: 'root',
        group: 'root',
        mode: '755'
      )
    end

    describe 'apache wsgi' do
      file = '/etc/apache2/sites-available/gnocchi-api.conf'
      it "creates #{file}" do
        expect(chef_run).to create_template(file).with(
          source: 'wsgi-template.conf.erb',
          variables: {
            ca_certs_path: '/etc/ceilometer/ssl/certs/',
            cert_file: '/etc/ceilometer/ssl/certs/sslcert.pem',
            cert_required: false,
            chain_file: nil,
            ciphers: nil,
            daemon_process: 'gnocchi-api',
            group: 'gnocchi',
            key_file: '/etc/ceilometer/ssl/private/sslkey.pem',
            log_debug: nil,
            log_dir: '/var/log/apache2',
            protocol: 'All -SSLv2 -SSLv3',
            run_dir: '/var/lock',
            server_entry: '/var/www/html/gnocchi/app',
            server_host: '127.0.0.1',
            server_port: 8041,
            user: 'gnocchi',
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
          /^<VirtualHost 127.0.0.1:8041>$/,
          /WSGIDaemonProcess gnocchi-api processes=2 threads=10 user=gnocchi group=gnocchi display-name=%{GROUP}$/,
          /WSGIProcessGroup gnocchi-api$/,
          %r{WSGIScriptAlias / /var/www/html/gnocchi/app$},
          %r{^WSGISocketPrefix /var/lock$},
          %r{ErrorLog /var/log/apache2/gnocchi-api_error.log$},
          %r{CustomLog /var/log/apache2/gnocchi-api_access.log combined$},
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
          node.override['openstack']['telemetry_metric']['ssl']['enabled'] = true
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
            node.override['openstack']['telemetry_metric']['ssl']['enabled'] = true
            node.override['openstack']['telemetry_metric']['ssl']['chainfile'] =
              '/etc/ceilometer/ssl/certs/chainfile.pem'
            node.override['openstack']['telemetry_metric']['ssl']['ciphers'] = 'ciphers_value'
            node.override['openstack']['telemetry_metric']['ssl']['cert_required'] = true
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
          expect(chef_run.template('/etc/apache2/sites-available/gnocchi-api.conf')).to \
            notify('service[apache2]').to(:restart)
        end
        it do
          expect(chef_run.apache2_site('gnocchi-api')).to notify('service[apache2]').to(:restart).immediately
        end
      end
    end
  end
end
