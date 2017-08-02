# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the api package' do
      expect(chef_run).to upgrade_package 'ceilometer-api'
    end
    it do
      expect(chef_run).to stop_service('ceilometer-api')
      expect(chef_run).to disable_service('ceilometer-api')
    end

    describe 'apache recipes' do
      it 'include apache recipes' do
        expect(chef_run).to include_recipe('apache2')
        expect(chef_run).to include_recipe('apache2::mod_wsgi')
        expect(chef_run).not_to include_recipe('apache2::mod_ssl')
      end

      it 'include apache recipes' do
        node.set['openstack']['telemetry']['ssl']['enabled'] = true
        expect(chef_run).to include_recipe('apache2::mod_ssl')
      end
    end

    it 'creates directory /var/www/html/ceilometer' do
      expect(chef_run).to create_directory('/var/www/html/ceilometer').with(
        user: 'root',
        group: 'root',
        mode: 0o0755
      )
    end

    it 'creates wsgi file' do
      expect(chef_run).to create_file('/var/www/html/ceilometer/app').with(
        user: 'root',
        group: 'root',
        mode: 0o0755
      )
    end

    describe 'apache wsgi' do
      file = '/etc/apache2/sites-available/ceilometer-api.conf'
      it "creates #{file}" do
        expect(chef_run).to create_template(file).with(
          user: 'root',
          group: 'root',
          mode: '0644'
        )
      end

      it "configures #{file} common lines" do
        node.set['openstack']['telemetry']['custom_template_banner'] = 'custom_template_banner_value'
        [/user=ceilometer/,
         /group=ceilometer/,
         %r{^  ErrorLog /var/log/apache2/ceilometer-api_error.log$},
         %r{^  CustomLog /var/log/apache2/ceilometer-api_access.log}].each do |line|
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
          node.set['openstack']['telemetry']['ssl']['enabled'] = true
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
          [/^        SSLCertificateChainFile/,
           /^          SSLCipherSuite/,
           /^          SSLVerifyClient require/].each do |line|
            expect(chef_run).not_to render_file(file).with_content(line)
          end
        end
        it "configures #{file} chainfile when set" do
          node.set['openstack']['telemetry']['ssl']['chainfile'] = '/etc/ceilometer/ssl/certs/chainfile.pem'
          expect(chef_run).to render_file(file)
            .with_content(%r{^          SSLCertificateChainFile /etc/ceilometer/ssl/certs/chainfile.pem$})
        end
        it "configures #{file} ciphers when set" do
          node.set['openstack']['telemetry']['ssl']['ciphers'] = 'ciphers_value'
          expect(chef_run).to render_file(file)
            .with_content(/^          SSLCipherSuite ciphers_value$/)
        end
        it "configures #{file} cert_required set" do
          node.set['openstack']['telemetry']['ssl']['cert_required'] = true
          expect(chef_run).to render_file(file)
            .with_content(/^          SSLVerifyClient require$/)
        end
      end

      describe 'ceilometer-api WSGI app' do
        it 'configures required lines' do
          [/^<VirtualHost 127.0.0.1:8777>$/,
           /^  WSGIDaemonProcess ceilometer-api/,
           /^  WSGIProcessGroup ceilometer-api$/,
           %r{^  WSGIScriptAlias / /var/www/html/ceilometer/app$}].each do |line|
            expect(chef_run).to render_file('/etc/apache2/sites-available/ceilometer-api.conf').with_content(line)
          end
        end
      end
    end
  end
end
