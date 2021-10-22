require_relative 'spec_helper'

describe 'openstack-telemetry::aodh' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'telemetry-stubs'

      case p
      when REDHAT_7
        it 'installs the aodh packages' do
          expect(chef_run).to upgrade_package %w(openstack-aodh-api openstack-aodh-evaluator openstack-aodh-expirer openstack-aodh-listener openstack-aodh-notifier python-aodhclient)
        end
      when REDHAT_8
        it 'installs the aodh packages' do
          expect(chef_run).to upgrade_package %w(openstack-aodh-api openstack-aodh-evaluator openstack-aodh-expirer openstack-aodh-listener openstack-aodh-notifier python3-aodhclient)
        end
      end

      it 'starts aodh services' do
        expect(chef_run).to start_service('openstack-aodh-evaluator')
        expect(chef_run).to start_service('openstack-aodh-notifier')
        expect(chef_run).to start_service('openstack-aodh-listener')
      end

      it 'subscribes to /etc/aodh/aodh.conf' do
        expect(chef_run.service('openstack-aodh-evaluator')).to subscribe_to('template[/etc/aodh/aodh.conf]')
        expect(chef_run.service('openstack-aodh-notifier')).to subscribe_to('template[/etc/aodh/aodh.conf]')
        expect(chef_run.service('openstack-aodh-listener')).to subscribe_to('template[/etc/aodh/aodh.conf]')
      end
    end
  end
end
