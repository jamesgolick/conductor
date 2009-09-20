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

    should "save the server objects in a hash, keyed by connection string" do
      s = SshSession.new("james@myserver.com", "james@myotherserver.com")
      assert_kind_of Net::SSH::Multi::Server, s.servers["james@myserver.com"]
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
      assert_kind_of SshSession::ResultProxy, @session.run("ls -la")
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

  context "The result object" do
    setup do
      @channels = [OpenStruct.new(:properties => {:host      => "server.com", 
                                                  :exit_code => 0}),
                   OpenStruct.new(:properties => {:host      => "otherserver.com",
                                                  :exit_code => 0})]
      @result = SshSession::ResultProxy.new(@channels)
    end

    context "when all of the exit_codes are 0" do
      should "be successful?" do
        assert @result.successful?
      end
    end

    context "when one or more hosts have failed" do
      setup do
        @channels.first.properties[:exit_code] = 127
        @result = SshSession::ResultProxy.new(@channels)
      end

      should "not be successful?" do
        assert !@result.successful?
      end

      should "return the hosts on which the command failed" do
        assert_equal "server.com", @result.failed_hosts.first.host
        assert_equal 127, @result.failed_hosts.first.exit_code
      end
    end
  end

  context "Putting some data" do
    setup do
      @session = SshSession.new("james@myserver.com", "fred@otherserver.com")
    end

    should "instantiate an SshSession::Upload for each server" do
      SshSession::Upload.expects(:new).
        with(@session.servers["james@myserver.com"], "/etc/chef/dna.json",
              "some data for myserver.com")
      SshSession::Upload.expects(:new).
        with(@session.servers["fred@otherserver.com"], "/etc/chef/dna.json",
              "some data for otherserver.com")
      @session.put "james@myserver.com"     => "some data for myserver.com",
                   "fred@otherserver.com" => "some data for otherserver.com",
                   :path                    => "/etc/chef/dna.json"
    end
  end

  context "Instantiating an upload object" do
    setup do
      @session     = SshSession.new("james@myserver.com")
      @ssh_session = @session.servers.values.first
    end

    should "upload the data with net/sftp" do
      sftp_mock         = mock
      file_factory_mock = mock
      file_mock         = mock
      file_mock.expects(:<<).with("some data for myserver.com")
      file_factory_mock.expects(:open).
        with("/etc/chef/dna.json", "w").yields(file_mock)
      sftp_mock.expects(:file).returns(file_factory_mock)
      sftp_mock.expects(:wait)
      Net::SFTP.expects(:new).with(@ssh_session).returns(sftp_mock)
      @upload  = SshSession::Upload.new(@ssh_session,
                                        "/etc/chef/dna.json",
                                        "some data for myserver.com")
    end
  end
end
