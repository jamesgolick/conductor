require File.dirname(__FILE__) + '/../test_helper'

class InstanceTest < Test::Unit::TestCase
  def setup
    Ec2.mode            = :test
    Ec2.test_mode_calls = {}
    @instance           = Factory(:mysql_master)
  end

  should_belong_to :environment
  should_have_many :chef_logs
  should_allow_values_for :size, Instance::SIZES
  should_not_allow_values_for :size, %w(other stuff), :message => /invalid size/i
  should_allow_values_for :role, Instance::ROLES
  should_not_allow_values_for :role, %w(other stuff), :message => /invalid role/i
  should_allow_values_for :zone, Instance::ZONES
  should_not_allow_values_for :zone, %w(us-east-1z), :message => /invalid zone/i

  context "When creating an app-server instance with no db server" do
    setup do
      @environment = Factory(:environment)
      @instance = Factory.build(:app_server, :environment => @environment)
      @instance.save
    end

    should "not save" do
      assert @instance.new_record?
    end

    should "have an error that you need to launch a db server first" do
      assert_match(/You must launch a database server/, @instance.errors[:base])
    end
  end
  
  context "After creating an instance" do
    setup do
      @instance = Factory.build(:mysql_master)
      @instance.save
    end

    should "create the instance on ec2" do
      expected_launch_params = {
        :groups  => ['default'],
        :keypair => 'conductor-keypair',
        :ami     => Instance.ami_for(@instance.size),
        :instance_type => @instance.size,
        :availability_zone => @instance.zone
      }
      assert_equal expected_launch_params, Ec2.test_mode_calls[:run_instances].first
    end
    
    should "save the instance_id that it gets from amazon" do
      id = Ec2.test_responses[:run_instances][:aws_instance_id]
      assert_equal id, @instance.instance_id
    end

    should "have a status of pending" do
      assert_equal 'pending', @instance.status
    end
  end

  context "When a pending instance becomes running" do
    setup do
      Bootstrapper.any_instance.stubs(:bootstrap)
      @instance.running! :private_dns_name => "private.host.name",
                         :dns_name         => "public.host.name"
    end

    should "grab the public hostname that's passed along" do
      assert_equal "public.host.name", @instance.dns_name
    end

    should "grab the private host name that's passed along" do
      assert_equal "private.host.name", @instance.private_dns_name
    end

    should "set the status to running" do
      assert @instance.running?
    end

    before_should "bootstrap the instance" do
      Bootstrapper.expects(:new).with(@instance).returns(mock(:bootstrap => true))
    end
  end

  context "Setting an instance as bootstrapped" do
    should "set the status to bootstrapped" do
      @instance = Factory(:running_instance)
      @instance.bootstrapped!
      assert @instance.bootstrapped?
    end
  end
end
