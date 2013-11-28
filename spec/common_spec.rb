require_relative "spec_helper"

describe "openstack-metering::common" do
  before { metering_stubs }
  describe "ubuntu" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new(::UBUNTU_OPTS) do |n|
        n.set["openstack"]["metering"]["syslog"]["use"] = true
      end
      @chef_run.converge "openstack-metering::common"
    end

    it "runs logging recipe" do
      expect(@chef_run).to include_recipe "openstack-common::logging"
    end

    it "installs the common package" do
      expect(@chef_run).to install_package "ceilometer-common"
    end

    describe "/etc/ceilometer" do
      before do
        @dir = @chef_run.directory "/etc/ceilometer"
      end

      it "has proper owner" do
        expect(@dir).to be_owned_by "ceilometer", "ceilometer"
      end

      it "has proper modes" do
        expect(sprintf("%o", @dir.mode)).to eq "750"
      end
    end

    describe "/etc/ceilometer" do
      before do
        @file = @chef_run.template "/etc/ceilometer/ceilometer.conf"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by("ceilometer", "ceilometer")
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq("640")
      end

      it "has rabbit_user" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_userid = guest"
      end

      it "has rabbit_password" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_password = rabbit-pass"
      end

      it "has rabbit_port" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_port = 5672"
      end

      it "has rabbit_host" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_host = 127.0.0.1"
      end

      it "has rabbit_virtual_host" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_virtual_host = /"
      end

      it "has auth_uri" do
        expect(@chef_run).to create_file_with_content @file.name,
          "auth_uri = http://127.0.0.1:5000/v2.0"
      end

      it "has auth_host" do
        expect(@chef_run).to create_file_with_content @file.name,
          "auth_host = 127.0.0.1"
      end

      it "has auth_port" do
        expect(@chef_run).to create_file_with_content @file.name,
          "auth_port = 35357"
      end

      it "has auth_protocol" do
        expect(@chef_run).to create_file_with_content @file.name,
          "auth_protocol = http"
      end
    end

    describe "qpid" do
      before do
        @file = @chef_run.template "/etc/ceilometer/ceilometer.conf"
        @chef_run.node.set['openstack']['metering']['mq']['service_type'] = "qpid"
      end

      it "has qpid_hostname" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_hostname=127.0.0.1"
      end

      it "has qpid_port" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_port=5672"
      end

      it "has qpid_username" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_username="
      end

      it "has qpid_password" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_password="
      end

      it "has qpid_sasl_mechanisms" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_sasl_mechanisms="
      end

      it "has qpid_reconnect" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect=true"
      end

      it "has qpid_reconnect_timeout" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect_timeout=0"
      end

      it "has qpid_reconnect_limit" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect_limit=0"
      end

      it "has qpid_reconnect_interval_min" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect_interval_min=0"
      end

      it "has qpid_reconnect_interval_max" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect_interval_max=0"
      end

      it "has qpid_reconnect_interval_max" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect_interval_max=0"
      end

      it "has qpid_reconnect_interval" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_reconnect_interval=0"
      end

      it "has qpid_heartbeat" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_heartbeat=60"
      end

      it "has qpid_protocol" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_protocol=tcp"
      end

      it "has qpid_tcp_nodelay" do
        expect(@chef_run).to create_file_with_content @file.name,
          "qpid_tcp_nodelay=true"
      end
    end

    describe "/etc/ceilometer/policy.json" do
      before do
        @dir = @chef_run.cookbook_file "/etc/ceilometer/policy.json"
      end

      it "has proper owner" do
        expect(@dir).to be_owned_by "ceilometer", "ceilometer"
      end

      it "has proper modes" do
        expect(sprintf("%o", @dir.mode)).to eq "640"
      end
    end
  end
end
