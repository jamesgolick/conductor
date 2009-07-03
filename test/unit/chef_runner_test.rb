require File.expand_path('../../test_helper', __FILE__)

class ChefRunnerTest < Test::Unit::TestCase
  def setup
    Ec2.mode = :test
    @instance = Factory(:running_instance)
    @instance.stubs(:connection_string).returns("a@b.com")
    @ssh = ssh_stub
  end

  context "Running chef on an instance" do
    should "run  an ssh/multi connection to that instance" do
      @ssh.expects(:use).with(@instance.connection_string)
      Net::SSH::Multi.expects(:start).yields(@ssh)
      run_chef
    end

    should "execute chef-solo -j /etc/chef/dna.json" do
      channel = stub_everything
      channel.expects(:exec).
        with("chef-solo -j /etc/chef/dna.json")
      @ssh.stubs(:open_channel).yields(channel)
      Net::SSH::Multi.expects(:start).yields(@ssh)
      run_chef
    end
  end

  protected
    def ssh_stub
      session = stub_everything
    end

    def run_chef
      ChefRunner.new(@instance.connection_string).run_chef
    end
end
