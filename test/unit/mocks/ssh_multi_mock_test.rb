require File.expand_path('../../../test_helper', __FILE__)
require 'test/mocks/ssh_multi_mock'

class SSHMultiMockTestTest < ActiveSupport::TestCase
  context "Using a server" do
    setup do
      @ssh = SSHMultiMock.new
      @ssh.use "james@myserver.com"
    end

    should "record the servers that are in use" do
      assert_equal ["james@myserver.com"], @ssh.servers_used
    end
  end
end
