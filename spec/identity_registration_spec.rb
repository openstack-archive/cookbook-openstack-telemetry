require_relative 'spec_helper'

describe 'openstack-telemetry::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    %w(telemetry telemetry_metric).each do |telemetry_service|
      case telemetry_service
      when 'telemetry'
        service_name = 'ceilometer'
        service_type = 'metering'
        password = 'ceilometer-pass'
      when 'telemetry_metric'
        service_name = 'gnocchi'
        service_type = 'metric'
        password = 'gnocchi-pass'
        port = 8041
      end

      connection_params = {
        openstack_auth_url: 'http://127.0.0.1:5000/v3',
        openstack_username: 'admin',
        openstack_api_key: 'admin-pass',
        openstack_project_name: 'admin',
        openstack_domain_name: 'default',
        openstack_endpoint_type: 'internalURL',
      }
      service_user = service_name
      url = "http://127.0.0.1:#{port}"
      region = 'RegionOne'
      project_name = 'service'
      role_name = 'admin'
      domain_name = 'Default'

      it "registers #{project_name} Project" do
        expect(chef_run).to create_openstack_project(
          project_name
        ).with(
          connection_params: connection_params
        )
      end

      it "registers #{service_name} service" do
        expect(chef_run).to create_openstack_service(
          service_name
        ).with(
          connection_params: connection_params,
          type: service_type
        )
      end

      unless telemetry_service == 'telemetry'
        describe "registers #{service_name} endpoint" do
          %w(internal public).each do |interface|
            it "#{interface} endpoint with default values" do
              expect(chef_run).to create_openstack_endpoint(
                service_type
              ).with(
                service_name: service_name,
                # interface: interface,
                url: url,
                region: region,
                connection_params: connection_params
              )
            end
          end
        end
      end

      it 'registers service user' do
        expect(chef_run).to create_openstack_user(
          service_user
        ).with(
          domain_name: domain_name,
          project_name: project_name,
          role_name: role_name,
          password: password,
          connection_params: connection_params
        )
      end
    end
  end
end
