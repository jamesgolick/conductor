require File.expand_path('../../test_helper', __FILE__)
require 'test/mocks/ssh_multi_mock'

class SshSessionTest < Test::Unit::TestCase
  context "Initializing an SSH session" do
    should "tell the ssh session to use all of the hosts" do
      Net::SSH::Multi::Session.any_instance.
        expects(:use).with("james@myserver.com", :forward_agent => true)
      Net::SSH::Multi::Session.any_instance.
        expects(:use).with("james@myotherserver.com", :forward_agent => true)
      SshSession.new("james@myserver.com", "james@myotherserver.com")
    end
  end

  context "Running an SSH command" do
    setup do
      @session    = SshSession.new("james@myserver.com")
      @multi_mock = SSHMultiMock.new
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, :stdout, "stdout"
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, :stdout, " output\n"
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, :stderr, "stderr output\n"
      @multi_mock.set_exit_code "ls -la", 0
      @session.stubs(:ssh).returns(@multi_mock)

      @result    = @session.run("ls -la")
    end

    should "yield the log lines to the supplied block" do
      yields = []
      block  = lambda { |line| yields << line } 
      @session.run("ls -la", &block)
      
      assert_equal "[STDOUT]: stdout", yields.first
      assert_equal " output\n", yields[1]
      assert_equal "[STDERR]: stderr output\n", yields[2]
    end
  end
end
