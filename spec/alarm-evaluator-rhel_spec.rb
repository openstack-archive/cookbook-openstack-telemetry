# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::alarm-evaluator' do
  describe 'rhel' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the alarm-evaluator package' do
      expect(chef_run).to upgrade_package 'openstack-ceilometer-alarm'
    end

    it 'starts the alarm-evaluator service' do
      expect(chef_run).to start_service 'openstack-ceilometer-alarm-evaluator'
    end
  end
end
