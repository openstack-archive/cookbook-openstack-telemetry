require_relative 'spec_helper'

describe 'openstack-telemetry::common' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'telemetry-stubs'

      case p
      when REDHAT_7
        it do
          expect(chef_run).to upgrade_package 'MySQL-python'
        end
      when REDHAT_8
        it do
          expect(chef_run).to upgrade_package 'python3-PyMySQL'
        end
      end

      it 'installs the common packages' do
        expect(chef_run).to upgrade_package %w(openstack-ceilometer-common)
      end
    end
  end
end
