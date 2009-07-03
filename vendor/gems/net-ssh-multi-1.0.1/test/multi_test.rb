require 'common'
require 'net/ssh/multi'

class MultiTest < Test::Unit::TestCase
  def test_start_with_block_should_yield_session_and_then_close
    Net::SSH::Multi::Session.any_instance.expects(:loop)
    Net::SSH::Multi::Session.any_instance.expects(:close)
    yielded = false
    Net::SSH::Multi.start do |session|
      yielded = true
      assert_instance_of Net::SSH::Multi::Session, session
    end
  end

  def test_start_without_block_should_return_open_session
    Net::SSH::Multi::Session.any_instance.expects(:loop).never
    Net::SSH::Multi::Session.any_instance.expects(:close).never
    assert_instance_of Net::SSH::Multi::Session, Net::SSH::Multi.start
  end
end