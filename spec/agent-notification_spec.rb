# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::agent-notification' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'
    include_examples 'expect-runs-common-recipe'

    it 'installs the agent-notification package' do
      expect(chef_run).to install_package 'ceilometer-agent-notification'
    end

    it 'starts ceilometer-agent-notification service' do
      expect(chef_run).to start_service('ceilometer-agent-notification')
    end
  end
end
