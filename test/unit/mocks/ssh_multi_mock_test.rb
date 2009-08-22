require File.expand_path('../../../test_helper', __FILE__)
require 'test/mocks/ssh_multi_mock'

class SSHMultiMockTestTest < ActiveSupport::TestCase
  def setup
    @ssh = SSHMultiMock.new
  end

  context "Using a server" do
    setup do
      @ssh.use "james@myserver.com"
    end

    should "record the servers that are in use" do
      assert_equal ["james@myserver.com"], @ssh.servers_used
    end
  end

  context "Running a command with configured yields" do
    setup do
      @ssh.add_command_response "ls -la", {:host => "whatever"}, :stdout, "the stdout data"
      @ssh.add_command_response "ls -la", {:host => "whatever"}, :stderr, "the stderr data"
    end

    should "yield them to the block passed to exec in order" do
      calls = []
      block_stub = lambda { |*response| calls << response }
      @ssh.exec("ls -la", &block_stub)

      assert_equal [{:host => "whatever"}, :stdout, "the stdout data"], calls.first
      assert_equal [{:host => "whatever"}, :stderr, "the stderr data"], calls[1]
    end
  end
end
