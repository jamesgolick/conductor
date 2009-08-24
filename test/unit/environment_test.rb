require File.dirname(__FILE__) + '/../test_helper'

class EnvironmentTest < Test::Unit::TestCase
  should_belong_to :application
  should_have_many :instances
  should_validate_presence_of :name

  def setup
    Ec2.mode = :test
  end

  context "When a database server has been created" do
    setup do
      @instance = Factory(:mysql_master)
    end

    should "be has_database_server?" do
      assert @instance.environment.has_database_server?
    end
  end

  context "When a database server has not been created" do
    setup do
      @environment = Factory(:environment)
    end

    should "not be has_database_server?" do
      assert !@environment.has_database_server?
    end
  end

  context "Getting the instances as a hash" do
    setup do
      @environment = Factory(:environment)
      @db  = Factory(:mysql_master, :environment      => @environment,
                                    :private_dns_name => "mysql_master.local")
      @db.update_attribute :aws_state, "running"

      @app = Factory(:app_server,   :environment      => @environment,
                                    :private_dns_name => "app.local")
      @app.update_attribute :aws_state, "running"
      
      Factory(:app_server,   :environment      => @environment,
                             :private_dns_name => "app.local")
    end

    should "create a 2-level hash with the running servers' privatedns names" do
      expected = {
        :app          => ["app.local"],
        :mysql_master => ["mysql_master.local"]
      }
      assert_equal expected, @environment.instances.to_dna
    end
  end

  context "Getting the environment as dna" do
    setup do
      @environment = Factory(:environment)

      @db = Factory(:mysql_master, :environment      => @environment,
                                   :private_dns_name => "db.local")
      @db.update_attribute :aws_state, "running"
    end

    should "include the application name" do
      assert_equal @environment.application.name, @environment.to_dna[:apps].first
    end

    should "include the instances dna" do
      assert_equal @environment.instances.to_dna, @environment.to_dna[:servers]
    end

    should "include the rails_env" do
      assert_equal @environment.name, @environment.to_dna[:rails_env]
    end

    should "include the domain" do
      assert_equal @environment.domain, @environment.to_dna[:app_domain]
    end

    should "set the user to the name of the app" do
      assert_equal @environment.application.name, @environment.to_dna[:user]
    end
  end
end
