# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    %w(telemetry telemetry-metric).each do |telemetry_service|
      case telemetry_service
      when 'telemetry'
        service_name = 'ceilometer'
        service_type = 'metering'
        user_pass = 'ceilometer-pass'
        port = 8777
      when 'telemetry-metric'
        service_name = 'gnocchi'
        service_type = 'metric'
        user_pass = 'gnocchi-pass'
        port = 8041
      end

      it do
        expect(chef_run).to create_tenant_openstack_identity_register(
          "Register Service Tenant for #{telemetry_service}"
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          tenant_name: 'service',
          tenant_description: 'Service Tenant'
        )
      end

      it do
        expect(chef_run).to create_user_openstack_identity_register(
          "Register #{service_name} User"
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          tenant_name: 'service',
          user_name: service_name,
          user_pass: user_pass
        )
      end

      it do
        expect(chef_run).to grant_role_openstack_identity_register(
          "Grant 'admin' Role to #{service_name} User for Service Tenant"
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          tenant_name: 'service',
          user_name: service_name,
          role_name: 'admin'
        )
      end

      it do
        expect(chef_run).to create_service_openstack_identity_register(
          "Register Service #{telemetry_service}"
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: service_name,
          service_type: service_type
        )
      end

      context "registers #{service_type} endpoint" do
        it do
          expect(chef_run).to create_endpoint_openstack_identity_register(
            "Register #{service_type} Endpoint"
          ).with(
            auth_uri: 'http://127.0.0.1:35357/v2.0',
            bootstrap_token: 'bootstrap-token',
            service_type: service_type,
            endpoint_region: 'RegionOne',
            endpoint_adminurl: "http://127.0.0.1:#{port}",
            endpoint_internalurl: "http://127.0.0.1:#{port}",
            endpoint_publicurl: "http://127.0.0.1:#{port}"
          )
        end
      end
    end
  end
end
