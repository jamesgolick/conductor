require 'common'
require 'net/ssh/multi/server'
require 'net/ssh/multi/session_actions'

class SessionActionsTest < Test::Unit::TestCase
  class SessionActionsContainer
    include Net::SSH::Multi::SessionActions

    attr_reader :servers

    def initialize
      @servers = []
    end

    def default_user
      "user"
    end

    def use(h, o={})
      server = Net::SSH::Multi::Server.new(self, h, o)
      servers << server
      server
    end
  end

  def setup
    @session = SessionActionsContainer.new
  end

  def test_busy_should_be_true_if_any_server_is_busy
    srv1, srv2, srv3 = @session.use('h1'), @session.use('h2'), @session.use('h3')
    srv1.stubs(:busy?).returns(false)
    srv2.stubs(:busy?).returns(false)
    srv3.stubs(:busy?).returns(true)
    assert @session.busy?
  end

  def test_busy_should_be_false_if_all_servers_are_not_busy
    srv1, srv2, srv3 = @session.use('h1'), @session.use('h2'), @session.use('h3')
    srv1.stubs(:busy?).returns(false)
    srv2.stubs(:busy?).returns(false)
    srv3.stubs(:busy?).returns(false)
    assert !@session.busy?
  end

  def test_send_global_request_should_delegate_to_sessions
    s1 = mock('ssh')
    s2 = mock('ssh')
    s1.expects(:send_global_request).with("a", "b", "c").yields
    s2.expects(:send_global_request).with("a", "b", "c").yields
    @session.expects(:sessions).returns([s1, s2])
    calls = 0
    @session.send_global_request("a", "b", "c") { calls += 1 }
    assert_equal 2, calls
  end

  def test_open_channel_should_delegate_to_sessions_and_set_accessors_on_each_channel_and_return_multi_channel
    srv1 = @session.use('h1')
    srv2 = @session.use('h2')
    s1 = { :server => srv1 }
    s2 = { :server => srv2 }
    c1 = { :stub => :value }
    c2 = {}
    c1.stubs(:connection).returns(s1)
    c2.stubs(:connection).returns(s2)
    @session.expects(:sessions).returns([s1, s2])
    s1.expects(:open_channel).with("session").yields(c1).returns(c1)
    s2.expects(:open_channel).with("session").yields(c2).returns(c2)
    results = []
    channel = @session.open_channel do |c|
      results << c
    end
    assert_equal [c1, c2], results
    assert_equal "h1", c1[:host]
    assert_equal "h2", c2[:host]
    assert_equal srv1, c1[:server]
    assert_equal srv2, c2[:server]
    assert_instance_of Net::SSH::Multi::Channel, channel
    assert_equal [c1, c2], channel.channels
  end

  def test_exec_should_raise_exception_if_channel_cannot_exec_command
    c = { :host => "host" }
    @session.expects(:open_channel).yields(c).returns(c)
    c.expects(:exec).with('something').yields(c, false)
    assert_raises(RuntimeError) { @session.exec("something") }
  end

  def test_exec_with_block_should_pass_data_and_extended_data_to_block
    c = { :host => "host" }
    @session.expects(:open_channel).yields(c).returns(c)
    c.expects(:exec).with('something').yields(c, true)
    c.expects(:on_data).yields(c, "stdout")
    c.expects(:on_extended_data).yields(c, 1, "stderr")
    c.expects(:on_request)
    results = {}
    @session.exec("something") do |c, stream, data|
      results[stream] = data
    end
    assert_equal({:stdout => "stdout", :stderr => "stderr"}, results)
  end

  def test_exec_without_block_should_write_data_and_extended_data_lines_to_stdout_and_stderr
    c = { :host => "host" }
    @session.expects(:open_channel).yields(c).returns(c)
    c.expects(:exec).with('something').yields(c, true)
    c.expects(:on_data).yields(c, "stdout 1\nstdout 2\n")
    c.expects(:on_extended_data).yields(c, 1, "stderr 1\nstderr 2\n")
    c.expects(:on_request)
    $stdout.expects(:puts).with("[host] stdout 1\n")
    $stdout.expects(:puts).with("[host] stdout 2")
    $stderr.expects(:puts).with("[host] stderr 1\n")
    $stderr.expects(:puts).with("[host] stderr 2")
    @session.exec("something")
  end

  def test_exec_should_capture_exit_status_of_process
    c = { :host => "host" }
    @session.expects(:open_channel).yields(c).returns(c)
    c.expects(:exec).with('something').yields(c, true)
    c.expects(:on_data)
    c.expects(:on_extended_data)
    c.expects(:on_request).with("exit-status").yields(c, Net::SSH::Buffer.from(:long, 127))
    @session.exec("something")
    assert_equal 127, c[:exit_status]
  end

end