require File.dirname(__FILE__) + '/../test_helper'

class InstanceTest < Test::Unit::TestCase
  def setup
    Ec2.mode            = :test
    Ec2.test_mode_calls = {}
    @instance           = Factory(:mysql_master)
    @environment        = Factory(:environment)
    CookbookRepository.any_instance.stubs(:pull)
    CookbookRepository.any_instance.stubs(:clone)
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
    end

    context "launching the ec2 instance" do
      setup do
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

      should "have an aws_state of pending" do
        assert_equal 'pending', @instance.aws_state
      end

      should "have a config state of unconfigured" do
        assert @instance.unconfigured?
      end
    end

    should "fire off a job to wait for state change" do
      @instance.expects(:send_later).with(:wait_for_state_change)
      @instance.save
    end
  end

  context "After destroying an instances" do
    should "ask ec2 to destroy it" do
      Ec2.any_instance.expects(:terminate_instances).with(@instance.instance_id)
      @instance.destroy
    end

    should "set state to terminating" do
      @instance.destroy
      assert_equal "terminating", @instance.aws_state
    end
  end

  context "Updating the instance state" do
    setup do
      @environment.stubs(:has_database_server?).returns(true)
      @instance = Factory(:instance, :environment => @environment)
      @chef_stub = stub(:perform_deployment => nil)
      ChefDeploymentRunner.stubs(:new).returns(@chef_stub)
    end

    context "going in to running" do
      setup do
        Ec2.any_instance.stubs(:describe_instances).returns([describe_instances_result])
        @instance.update_instance_state
      end

      should "set the aws_state to running" do
        assert_equal "running", @instance.aws_state
      end

      should "grab the dns_name" do
        assert_equal describe_instances_result[:dns_name], @instance.dns_name
      end

      should "grab the private_dns_name" do
        assert_equal describe_instances_result[:private_dns_name], @instance.private_dns_name
      end

      should "grab the availability_zone" do
        assert_equal describe_instances_result[:aws_availability_zone], @instance.zone
      end

      before_should "notify the environment" do
        @instance.environment.expects(:notify_of).with(:running, @instance)
      end

      should "create a chef deployment" do
        assert_received(ChefDeploymentRunner, :new) do |e|
          e.with(@instance)
        end
        assert_received(@chef_stub, :perform_deployment)
      end
    end
  end

  context "Checking whether the aws state has changed" do
    setup do
      @environment.stubs(:has_database_server?).returns(true)
      @instance = Factory(:instance, :environment => @environment)
      Ec2.any_instance.stubs(:describe_instances).returns([describe_instances_result])
    end

    should "be aws_state_changed? if the aws state is different" do
      assert @instance.aws_state_changed?
    end

    should "not be aws_state_changed? if the aws state is the same" do
      @instance.stubs(:aws_state).returns("running")
      assert !@instance.aws_state_changed?
    end
  end

  context "An instance's dna" do
    should "delegate to dna with its role and cookbook repository" do
      CookbookRepository.any_instance.stubs(:clone).stubs(:pull)
      @instance = Factory(:instance, :role => "mysql_master")
      Dna.expects(:new).with(@instance.environment, @instance.role, @instance.cookbook_repository, @instance)
      @instance.dna
    end
  end

  context "Assiging an address" do
    setup do
      @instance = Factory.build(:instance, :role => "app")
      @instance.save(false)
      @instance.reload
    end

    should "assign it via ec2" do
      address = Address.create :address => "127.0.0.1"
      Ec2.any_instance.expects(:associate_address).with(@instance.instance_id, address.address)
      @instance.assign_address!(address)
    end

    should "associate it with itself" do
      address = Address.create
      @instance.assign_address!(address)
      assert_equal address, @instance.address
    end
  end

  context "When an instance is created" do
    should "notify the environment" do
      @instance = Factory.build(:mysql_master)
      @instance.environment.expects(:notify_of).with(:launch, @instance)
      @instance.save
    end
  end

  context "When an instance is terminated" do
    should "notify the environment" do
      @instance = Factory(:mysql_master)
      @instance.environment.expects(:notify_of).with(:termination, @instance)
      @instance.destroy
    end
  end

  context "The public address" do
    setup do
      @instance = Factory(:mysql_master)
    end

    should "be thte address, when one is attached" do
      @address  = Address.create
      @instance.assign_address!(@address)
      assert_equal @address.address, @instance.public_address
    end

    should "be the public dns anme otherwise" do
      @instance.update_attributes :dns_name => "dns.name"
      assert_equal "dns.name", @instance.public_address
    end
  end

  should "understand deployment_events from ChefDeploymentRunner" do
    @instance.deployment_event(ChefDeploymentRunner.new, :start)
    assert_equal "deploying", @instance.config_state
    @instance.deployment_event(ChefDeploymentRunner.new, :successful)
    assert_equal "deployed", @instance.config_state
    @instance.deployment_event(ChefDeploymentRunner.new, :failure)
    assert_equal "deployment_failed", @instance.config_state
    @instance.deployment_event(ChefDeploymentRunner.new, :cancelled)
    assert_equal "deployment_cancelled", @instance.config_state
  end

  context "When an instance has been deployed successfully for the first time" do
    setup do
      @instance.deployment_event(ChefDeploymentRunner.new, :successful)
    end

    should "set the instance to configured" do
      assert @instance.configured?
    end
  end

  protected
    def describe_instances_result
      {
        :dns_name              => "domU-12-34-67-89-01-C9.usma2.compute.amazonaws.com",
        :private_dns_name      => "domU-12-34-67-89-01-C9.usma2.compute.amazonaws.com",
        :aws_availability_zone => "us-east-1c",
        :aws_state             => "running"
      }
    end
end
