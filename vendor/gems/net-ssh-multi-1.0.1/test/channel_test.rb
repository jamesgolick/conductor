require 'common'
require 'net/ssh/multi/channel'

class ChannelTest < Test::Unit::TestCase
  def test_each_should_iterate_over_each_component_channel
    channels = [c1 = mock('channel'), c2 = mock('channel'), c3 = mock('channel')]
    channel = Net::SSH::Multi::Channel.new(mock('session'), channels)
    result = []
    channel.each { |c| result << c }
    assert_equal channels, result
  end

  def test_property_accessors
    channel = Net::SSH::Multi::Channel.new(mock('session'), [])
    channel[:foo] = "hello"
    assert_equal "hello", channel[:foo]
    channel['bar'] = "goodbye"
    assert_equal "goodbye", channel['bar']
    assert_nil channel[:bar]
    assert_nil channel['foo']
  end

  def test_exec_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:exec).with('ls -l').yields(c1)
    c2.expects(:exec).with('ls -l').yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.exec('ls -l') { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_request_pty_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:request_pty).with(:foo => 5).yields(c1)
    c2.expects(:request_pty).with(:foo => 5).yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.request_pty(:foo => 5) { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_send_data_should_delegate_to_component_channels
    c1, c2 = mock('channel'), mock('channel')
    c1.expects(:send_data).with("hello\n")
    c2.expects(:send_data).with("hello\n")
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.send_data("hello\n")
  end

  def test_active_should_be_true_if_all_component_channels_are_active
    c1, c2, c3 = stub('channel', :active? => true), stub('channel', :active? => true), stub('channel', :active? => true)
    channel = Net::SSH::Multi::Channel.new(stub('session'), [c1, c2, c3])
    assert channel.active?
  end

  def test_active_should_be_true_if_any_component_channels_are_active
    c1, c2, c3 = stub('channel', :active? => true), stub('channel', :active? => false), stub('channel', :active? => false)
    channel = Net::SSH::Multi::Channel.new(stub('session'), [c1, c2, c3])
    assert channel.active?
  end

  def test_active_should_be_false_if_no_component_channels_are_active
    c1, c2, c3 = stub('channel', :active? => false), stub('channel', :active? => false), stub('channel', :active? => false)
    channel = Net::SSH::Multi::Channel.new(stub('session'), [c1, c2, c3])
    assert !channel.active?
  end

  def test_wait_should_block_until_active_is_false
    channel = Net::SSH::Multi::Channel.new(MockSession.new, [])
    channel.expects(:active?).times(4).returns(true,true,true,false)
    assert_equal channel, channel.wait
  end

  def test_close_should_delegate_to_component_channels
    c1, c2 = mock('channel'), mock('channel')
    c1.expects(:close)
    c2.expects(:close)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.close
  end

  def test_eof_bang_should_delegate_to_component_channels
    c1, c2 = mock('channel'), mock('channel')
    c1.expects(:eof!)
    c2.expects(:eof!)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.eof!
  end

  def test_on_data_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:on_data).yields(c1)
    c2.expects(:on_data).yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.on_data { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_on_extended_data_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:on_extended_data).yields(c1)
    c2.expects(:on_extended_data).yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.on_extended_data { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_on_process_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:on_process).yields(c1)
    c2.expects(:on_process).yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.on_process { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_on_close_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:on_close).yields(c1)
    c2.expects(:on_close).yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.on_close { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_on_eof_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:on_eof).yields(c1)
    c2.expects(:on_eof).yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.on_eof { |c| results << c }
    assert_equal [c1, c2], results
  end

  def test_on_request_should_delegate_to_component_channels
    c1, c2, results = mock('channel'), mock('channel'), []
    c1.expects(:on_request).with("exit-status").yields(c1)
    c2.expects(:on_request).with("exit-status").yields(c2)
    channel = Net::SSH::Multi::Channel.new(mock('session'), [c1, c2])
    assert_equal channel, channel.on_request("exit-status") { |c| results << c }
    assert_equal [c1, c2], results
  end

  private

    class MockSession
      def loop
        while true do
          return if !yield(self)
        end
      end
    end
end