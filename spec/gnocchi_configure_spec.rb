require_relative 'spec_helper'

describe 'openstack-telemetry::gnocchi_configure' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    describe 'gnocchi.conf' do
      let(:file) { chef_run.template('/etc/gnocchi/gnocchi.conf') }

      it do
        expect(chef_run).to create_template(file.name).with(
          user: 'gnocchi',
          group: 'gnocchi',
          mode: 0o640
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
          mode: 0o0640
        )
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/gnocchi/api-paste.ini')
        .with(
          source: 'api-paste.ini',
          owner: 'gnocchi',
          group: 'gnocchi',
          mode: 0o0640
        )
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/ceilometer/event_pipeline.yaml')
        .with(
          source: 'event_pipeline.yaml',
          owner: 'ceilometer',
          group: 'ceilometer',
          mode: 0o0640
        )
    end

    %w(tmp measure cache).each do |dir|
      describe "gnocchi #{dir} dir" do
        context 'file as storage backend' do
          it do
            expect(chef_run).to create_directory("/var/lib/gnocchi/#{dir}")
              .with(
                user: 'gnocchi',
                group: 'gnocchi',
                mode: 0o750
              )
          end
        end
        context 'other storage backend' do
          before do
            node.override['openstack']['telemetry_metric']['conf']['storage']['driver'] = 'ceph'
          end
          it do
            expect(chef_run).to_not create_directory("/var/lib/gnocchi/#{dir}")
              .with(
                user: 'gnocchi',
                group: 'gnocchi',
                mode: 0o750
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

    describe 'apache recipes' do
      it 'include apache recipes' do
        expect(chef_run).to include_recipe('apache2')
        expect(chef_run).to include_recipe('apache2::mod_wsgi')
        expect(chef_run).not_to include_recipe('apache2::mod_ssl')
      end

      it 'include apache recipes' do
        node.override['openstack']['identity']['ssl']['enabled'] = true
        expect(chef_run).to include_recipe('apache2::mod_ssl')
      end
    end

    it 'creates directory /var/www/html/gnocchi' do
      expect(chef_run).to create_directory('/var/www/html/gnocchi').with(
        user: 'root',
        group: 'root',
        mode: 0o0755
      )
    end

    it 'creates wsgi file' do
      expect(chef_run).to create_file('/var/www/html/gnocchi/app').with(
        user: 'root',
        group: 'root',
        mode: 0o0755
      )
    end

    describe 'apache wsgi' do
      file = '/etc/apache2/sites-available/gnocchi-api.conf'
      it "creates #{file}" do
        expect(chef_run).to create_template(file).with(
          user: 'root',
          group: 'root',
          mode: '0644'
        )
      end

      it "configures #{file} common lines" do
        node.override['openstack']['telemetry_metric']['custom_template_banner'] = 'custom_template_banner_value'
        [/user=gnocchi/,
         /group=gnocchi/,
         %r{^  ErrorLog /var/log/apache2/gnocchi-api_error.log$},
         %r{^  CustomLog /var/log/apache2/gnocchi-api_access.log combined$}].each do |line|
          expect(chef_run).to render_file(file).with_content(line)
        end
      end

      it "does not configure #{file} triggered common lines" do
        [/^    LogLevel/,
         /^    SSL/].each do |line|
          expect(chef_run).not_to render_file(file).with_content(line)
        end
      end
      context 'Enable SSL' do
        before do
          node.override['openstack']['telemetry_metric']['ssl']['enabled'] = true
        end
        it "configures #{file} common ssl lines" do
          [/^      SSLEngine On$/,
           %r{^      SSLCertificateFile /etc/ceilometer/ssl/certs/sslcert.pem$},
           %r{^      SSLCertificateKeyFile /etc/ceilometer/ssl/private/sslkey.pem$},
           %r{^      SSLCACertificatePath /etc/ceilometer/ssl/certs/$},
           /^      SSLProtocol All -SSLv2 -SSLv3$/].each do |line|
            expect(chef_run).to render_file(file).with_content(line)
          end
        end
        it "does not configure #{file} common ssl lines" do
          [/^          SSLCertificateChainFile/,
           /^          SSLCipherSuite/,
           /^          SSLVerifyClient require/].each do |line|
            expect(chef_run).not_to render_file(file).with_content(line)
          end
        end
        it "configures #{file} chainfile when set" do
          node.override['openstack']['telemetry_metric']['ssl']['chainfile'] = '/etc/ceilometer/ssl/certs/chainfile.pem'
          expect(chef_run).to render_file(file)
            .with_content(%r{^          SSLCertificateChainFile /etc/ceilometer/ssl/certs/chainfile.pem$})
        end
        it "configures #{file} ciphers when set" do
          node.override['openstack']['telemetry_metric']['ssl']['ciphers'] = 'ciphers_value'
          expect(chef_run).to render_file(file)
            .with_content(/^          SSLCipherSuite ciphers_value$/)
        end
        it "configures #{file} cert_required set" do
          node.override['openstack']['telemetry_metric']['ssl']['cert_required'] = true
          expect(chef_run).to render_file(file)
            .with_content(/^          SSLVerifyClient require$/)
        end
      end

      describe 'gnocchi-api WSGI app' do
        it 'configures required lines' do
          [/^<VirtualHost 127.0.0.1:8041>$/,
           /^  WSGIDaemonProcess gnocchi-api/,
           /^  WSGIProcessGroup gnocchi-api$/,
           %r{^  WSGIScriptAlias / /var/www/html/gnocchi/app$}].each do |line|
            expect(chef_run).to render_file('/etc/apache2/sites-available/gnocchi-api.conf').with_content(line)
          end
        end
      end

      describe 'restart apache' do
        it do
          expect(chef_run).to nothing_execute('Clear gnocchi apache restart')
            .with(
              command: 'rm -f /var/chef/cache/gnocchi-apache-restarted'
            )
        end
        %w(
          /etc/gnocchi/gnocchi.conf
          /etc/apache2/sites-available/gnocchi-api.conf
        ).each do |f|
          it "#{f} notifies execute[Clear gnocchi apache restart]" do
            expect(chef_run.template(f)).to notify('execute[Clear gnocchi apache restart]').to(:run).immediately
          end
        end
        it do
          expect(chef_run).to run_execute('gnocchi apache restart')
            .with(
              command: 'touch /var/chef/cache/gnocchi-apache-restarted',
              creates: '/var/chef/cache/gnocchi-apache-restarted'
            )
        end
        it do
          expect(chef_run.execute('gnocchi apache restart')).to notify('execute[restore-selinux-context-gnocchi]').to(:run).immediately
        end
        it do
          expect(chef_run.execute('gnocchi apache restart')).to notify('service[apache2]').to(:restart).immediately
        end
      end
    end
  end
end
