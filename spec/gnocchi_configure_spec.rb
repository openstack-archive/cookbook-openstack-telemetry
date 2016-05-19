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
          mode: 0640
        )
      end

      it do
        [
          /^username = gnocchi$/,
          /^project_name = service$/,
          /^auth_type = password$/,
          /^region_name = RegionOne$/,
          %r{auth_url = http://127\.0\.0\.1:5000/v2\.0},
          /^password = gnocchi-pass$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', line)
        end
      end

      it do
        [
          /^host = 127\.0\.0\.1$/,
          /^port = 8041$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('api', line)
        end
      end

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'database',
            %r{^connection = mysql://gnocchi:gnocchi-dbpass@127\.0\.0\.1:3306/gnocchi\?charset=utf8$}
          )
      end

      it do
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'indexer',
            %r{^url = mysql://gnocchi:gnocchi-dbpass@127\.0\.0\.1:3306/gnocchi\?charset=utf8$}
          )
      end
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/ceilometer/gnocchi_resources.yaml')
        .with(
          source: 'gnocchi_resources.yaml',
          owner: 'ceilometer',
          group: 'ceilometer',
          mode: 00640
        )
    end

    it do
      expect(chef_run).to create_cookbook_file('/etc/gnocchi/api-paste.ini')
        .with(
          source: 'api-paste.ini',
          owner: 'gnocchi',
          group: 'gnocchi',
          mode: 00640
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
                mode: 0750
              )
          end
        end
        context 'other storage backend' do
          before do
            node.set['openstack']['telemetry-metric']['conf']['storage']['driver'] = 'ceph'
          end
          it do
            expect(chef_run).to_not create_directory("/var/lib/gnocchi/#{dir}")
              .with(
                user: 'gnocchi',
                group: 'gnocchi',
                mode: 0750
              )
          end
        end
      end
    end

    it do
      expect(chef_run).to run_execute('gnocchi-upgrade')
        .with(user: 'gnocchi')
    end

    %w(gnocchi-api gnocchi-metricd).each do |service|
      it do
        expect(chef_run).to enable_service(service)
      end
      it do
        expect(chef_run).to start_service(service)
      end
    end
  end
end
