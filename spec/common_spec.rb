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

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content('DEFAULT', /^meter_dispatchers = gnocchi$/)
      end

      it do
        [
          /^username = ceilometer$/,
          /^project_name = service$/,
          /^user_domain_name = Default/,
          /^project_domain_name = Default/,
          /^auth_type = v3password$/,
          /^region_name = RegionOne$/,
          %r{auth_url = http://127\.0\.0\.1:5000/v3},
          /^password = ceilometer-pass$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', line)
        end
      end

      it do
        [
          /^username = ceilometer$/,
          /^project_name = service$/,
          /^user_domain_name = Default/,
          /^project_domain_name = Default/,
          /^auth_type = v3password$/,
          /^interface = internal$/,
          /^region_name = RegionOne$/,
          %r{auth_url = http://127\.0\.0\.1:5000/v3},
          /^password = ceilometer-pass$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('service_credentials', line)
        end
      end

      it do
        [
          /^host = 127\.0\.0\.1$/,
          /^port = 8777$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('api', line)
        end
      end

      it do
        [
          %r{url = http://127\.0\.0\.1:8041},
          /^filter_project = service$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('dispatcher_gnocchi', line)
        end
      end

      it do
        [
          /^rabbit_userid = guest$/,
          /^rabbit_password = mq-pass$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('oslo_messaging_rabbit', line)
        end
      end

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'database',
            %r{^connection = mysql://ceilometer:ceilometer-dbpass@127\.0\.0\.1:3306/ceilometer\?charset=utf8$}
          )
      end
    end
  end
end
