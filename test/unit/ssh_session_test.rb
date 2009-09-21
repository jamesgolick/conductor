require 'test_helper'

class SshSessionTest < ActiveSupport::TestCase
  context "Instantiating an ssh recipe" do
    setup do
      @recipe = SshSession.new("james@myserver.com") do
        put "asdf"
        run "ls -la"
        run "other stuffs"
      end
    end

    should "collect the commands" do
      assert_equal [:put, "asdf"], @recipe.commands[0]
      assert_equal [:run, "ls -la"], @recipe.commands[1]
      assert_equal [:run, "other stuffs"], @recipe.commands[2]
    end

    should "instantiate a session with the supplied servers" do
      assert_equal ["james@myserver.com"], @recipe.ssh.servers.keys
    end
  end

  context "Running a recipe" do
    setup do
      @recipe  = SshSession.new do
        run "ls -la"
        run "rm -Rf /"
      end
    end

    should "run it on the session" do
      @recipe.ssh.expects(:run).with("ls -la").returns(stub(:successful? => true))
      @recipe.ssh.expects(:run).with("rm -Rf /").returns(stub(:successful? => true))
      @recipe.execute
    end

    should "call the before_command callback before a command is run" do
      @recipe.ssh.stubs(:run).returns(stub(:successful? => true))
      commands = []
      @recipe.before_command do |t, c|
        commands << [t,c]
      end
      @recipe.execute
      assert_equal [[:run, "ls -la"], [:run, "rm -Rf /"]], commands
    end

    should "pass the data from Ssh#run along to the on_data callback" do
      @recipe.ssh.stubs(:run).yields("myserver.com", :stdout, "data").
        returns(stub(:successful? => true))
      calls = []
      @recipe.on_data do |host, stream, data|
        calls << [host, stream, data]
      end
      @recipe.execute

      assert_equal ["myserver.com", :stdout, "data"], calls.first
    end

    context "when a command fails" do
      setup do
        @proxy = Ssh::ResultProxy.new([stub(:successful? => false)])
        @recipe.ssh.stubs(:run).with("ls -la").returns(@proxy)
        @recipe.ssh.expects(:run).with("rm -Rf /").never
      end

      should "stop running the commands and return the result set" do
        assert_equal [@proxy], @recipe.execute
      end

      should "return a ResultSet" do
        assert_kind_of SshSession::ResultSet, @recipe.execute
      end

      should "be a cancelled result" do
        assert @recipe.execute.cancelled?
      end
    end

    context "if the last command fails" do
      setup do
        @win  = Ssh::ResultProxy.new([stub(:successful? => true)])
        @fail = Ssh::ResultProxy.new([stub(:successful? => false)])
        @recipe.ssh.stubs(:run).with("ls -la").returns(@win)
        @recipe.ssh.expects(:run).with("rm -Rf /").returns(@fail)
      end

      should "not be a result of cancelled" do
        assert !@recipe.execute.cancelled?
      end

      should "be a failure" do
        assert !@recipe.execute.successful?
      end
    end
  end
  
  context "SshSession::ResultSet" do
    setup do
      @result_set = SshSession::ResultSet.new
      success     = Ssh::Result.new :host      => "whatever.com",
                                    :exit_code => 0
      failure     = Ssh::Result.new :host      => "otherstuff.com",
                                    :exit_code => 1
      @result_set << Ssh::ResultProxy.new(success)
      @result_set << Ssh::ResultProxy.new(failure)
    end

    should "be able to return the hosts upon which a command failed" do
      assert_equal ["otherstuff.com"], @result_set.failed_hosts
    end
  end
end
