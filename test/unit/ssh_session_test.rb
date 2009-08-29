require File.expand_path('../../test_helper', __FILE__)
require 'test/mocks/ssh_multi_mock'

class SshSessionTest < Test::Unit::TestCase
  context "Initializing an SSH session" do
    should "tell the ssh session to use all of the hosts" do
      Net::SSH::Multi::Session.any_instance.
        expects(:use).with("james@myserver.com", :forward_agent => true)
      SshSession.new("james@myserver.com")
    end
  end

  context "Running an SSH command" do
    setup do
      @session    = SshSession.new("james@myserver.com")
      @multi_mock = SSHMultiMock.new
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, :stdout, "stdout output\n"
      @multi_mock.add_command_response "ls -la", {:host => "james@myserver.com"}, :stderr, "stderr output\n"
      @multi_mock.set_exit_code "ls -la", 0
      @session.stubs(:ssh).returns(@multi_mock)

      @result    = @session.run("ls -la")
      @log_lines = @result.log.split("\n")
    end

    should "yield the log lines to the supplied block" do
      lines = []
      block = lambda { |line| lines << line } 
      @session.run("ls -la", &block)
      
      assert_equal "[james@myserver.com STDOUT]: stdout output\n", lines.first
      assert_equal "[james@myserver.com STDERR]: stderr output\n", lines[1]
    end

    should "return the log of the command" do
      assert_equal "[james@myserver.com STDOUT]: stdout output", @log_lines.first
      assert_equal "[james@myserver.com STDERR]: stderr output", @log_lines[1]
    end

    should "return the exit code" do
      assert_equal 0, @result.exit_code
    end

    should "return the host" do
      assert_equal "james@myserver.com", @result.host
    end
  end

  context "Running an SFTP command" do
    setup do
      @session = SshSession.new("james@myserver.com")
    end

    should "split the user from the host before passing it to net/sftp" do
      Net::SFTP.expects(:start).with("myserver.com", "james").returns(stub_everything)
      @session.upload("some_file")
    end

    should "upload the file immediately via sftp" do
      session_mock = mock
      session_mock.expects(:upload!).with("somefile", "somefile")
      Net::SFTP.stubs(:start).returns(session_mock)

      @session.upload("somefile")
    end
  end

  context "Putting a string via sftp" do
    should "put the file using net/sftp" do
      @session = SshSession.new("james@myserver.com")
      open_file_stub = stub
      open_file_stub.expects(:puts).with("the value")
      file_stub      = stub
      file_stub.expects(:open).with("/etc/chef/dna.json", "w").yields(open_file_stub)
      sftp_stub      = stub
      sftp_stub.stubs(:file).returns(file_stub)
      @session.stubs(:sftp).returns(sftp_stub)
      @session.put("the value", "/etc/chef/dna.json")
    end
  end
end
