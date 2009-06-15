require File.expand_path('../../test_helper', __FILE__)

class SshSessionTest < Test::Unit::TestCase
  context "Opening an SSH session with a machine" do
    should "open a session to the server" do
      Net::SSH.expects(:start).with("some_machine", "root")
      SshSession.new("root@some_machine") do
        run "ls -la"
      end
    end

    should "run a command on it" do
      ssh_stub do |s|
        s.expects(:exec).with("ls -la")
        s.expects(:loop)
      end

      SshSession.new("root@some_machine") do
        run "ls -la"
      end
    end
  end

  protected
    def ssh_stub
      ssh_stub = mock
      Net::SSH.stubs(:start).yields(ssh_stub)
      yield ssh_stub
    end
end
