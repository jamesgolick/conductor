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
      @session    = SshSession.new("james@myserver.com", "fred@otherserver.com")
      @multi_mock = SSHMultiMock.new
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, 
                                        :stdout, "stdout"
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, 
                                        :stdout, " output\n"
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, 
                                        :stderr, "stderr output\n"
      @multi_mock.add_command_response "ls -la", {:host => "fred@otherserver.com"}, 
                                        :stderr, "stderr output\n"
      @multi_mock.set_exit_code "james@myserver.com",   "ls -la", 0
      @multi_mock.set_exit_code "fred@otherserver.com", "ls -la", 0
      @session.stubs(:ssh).returns(@multi_mock)
    end

    should "return a result object" do
      assert_kind_of SshSession::Result, @session.run("ls -la")
    end

    should "yield the results to the supplied block" do
      yields = []
      @session.run("ls -la") { |host, stream, line| yields << [host, stream, line] }
      expected = [["james@myserver.com", :stdout, "stdout"],
                  ["james@myserver.com", :stdout, " output\n"],
                  ["james@myserver.com", :stderr, "stderr output\n"],
                  ["fred@otherserver.com", :stderr, "stderr output\n"]]
      expected.each_with_index do |y, i|
        assert_equal y, yields[i]
      end
    end
  end
end
