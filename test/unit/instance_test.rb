require File.dirname(__FILE__) + '/../test_helper'

class InstanceTest < Test::Unit::TestCase
  def setup
    Ec2.mode            = :test
    Ec2.test_mode_calls = {}
    @instance           = Factory(:mysql_master)
    @environment        = Factory(:environment)
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

  context "starting the deployment" do
    should "create a chef deployment" do
      @instance = Factory(:running_instance)
      @instance.stubs(:chef_deployments).returns(mock(:create => nil))
      @instance.deploy
    end
  end

  context "Setting an instance as bootstrapped" do
    should "set the config_state to bootstrapped and start deploying" do
      @instance = Factory(:running_instance)
      @instance.expects(:deploy)
      @instance.bootstrapped!
      assert @instance.bootstrapped?
    end
  end

  context "Setting an instance as bootstrapping" do
    should "set the config_state to bootstrapping" do
      @instance = Factory(:running_instance)
      @instance.bootstrapping!
      assert @instance.bootstrapping?
    end
  end

  context "Setting an instance as deployed" do
    should "set the config_state to deployed" do
      @instance = Factory(:running_instance)
      @instance.deployed!
      assert @instance.deployed?
    end
  end

  context "Setting an instance as deploying" do
    should "set the config_state to deploying" do
      @instance = Factory(:running_instance)
      @instance.deploying!
      assert @instance.deploying?
    end
  end

  context "Setting an instance as deployment_failed" do
    should "set the config_state to deployment_failed" do
      @instance = Factory(:running_instance)
      @instance.deployment_failed!
      assert @instance.deployment_failed?
    end
  end

  context "After destroying an instances" do
    should "ask ec2 to destroy it" do
      Ec2.any_instance.expects(:terminate_instances).with(@instance.instance_id)
      @instance.destroy
    end
  end

  context "Updating the instance state" do
    setup do
      @environment.stubs(:has_database_server?).returns(true)
      @instance = Factory(:instance, :environment => @environment)
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

      before_should "start the bootstrapping job" do
        @instance.expects(:bootstrap)
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

  context "Asking an instance to bootstrap" do
    should "create a bootstrap deployment" do
      @instance = Factory(:instance, :role => "mysql_master")
      @instance.stubs(:bootstrap_deployments).returns(mock(:create => nil))
      @instance.bootstrap
    end
  end

  context "An instance's dna" do
    should "delegate to dna with its role and cookbook repository" do
      CookbookRepository.any_instance.stubs(:clone).stubs(:pull)
      @instance = Factory(:instance, :role => "mysql_master")
      Dna.expects(:new).with(@instance.role, @instance.cookbook_repository)
      @instance.dna
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
