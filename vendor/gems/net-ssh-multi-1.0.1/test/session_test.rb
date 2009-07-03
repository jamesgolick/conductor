require 'common'
require 'net/ssh/multi/session'

class SessionTest < Test::Unit::TestCase
  def setup
    @session = Net::SSH::Multi::Session.new
  end

  def test_group_should_fail_when_given_both_mapping_and_block
    assert_raises(ArgumentError) do
      @session.group(:app => mock('server')) { |s| }
    end
  end

  def test_group_with_block_should_use_groups_within_block_and_restore_on_exit
    @session.open_groups.concat([:first, :second])
    assert_equal [:first, :second], @session.open_groups
    yielded = nil
    @session.group(:third, :fourth) do |s|
      yielded = s
      assert_equal [:first, :second, :third, :fourth], @session.open_groups
    end
    assert_equal [:first, :second], @session.open_groups
    assert_equal @session, yielded
  end

  def test_group_with_mapping_should_append_new_servers_to_specified_and_open_groups
    s1, s2, s3, s4 = @session.use('h1', 'h2', 'h3', 'h4')
    @session.group :second => s1
    @session.open_groups.concat([:first, :second])
    @session.group %w(third fourth) => [s2, s3], :fifth => s1, :sixth => [s4]
    assert_equal [s1, s2, s3, s4], @session.groups[:first].sort
    assert_equal [s1, s2, s3, s4], @session.groups[:second].sort
    assert_equal [s2, s3], @session.groups[:third].sort
    assert_equal [s2, s3], @session.groups[:fourth].sort
    assert_equal [s1], @session.groups[:fifth].sort
    assert_equal [s4], @session.groups[:sixth].sort
  end

  def test_via_should_instantiate_and_set_default_gateway
    Net::SSH::Gateway.expects(:new).with('host', 'user', :a => :b).returns(:gateway)
    assert_equal @session, @session.via('host', 'user', :a => :b)
    assert_equal :gateway, @session.default_gateway
  end

  def test_use_should_add_new_server_to_server_list
    @session.open_groups.concat([:first, :second])
    server = @session.use('user@host', :a => :b)
    assert_equal [server], @session.servers
    assert_equal 'host', server.host
    assert_equal 'user', server.user
    assert_equal({:a => :b}, server.options)
    assert_nil server.gateway
  end

  def test_use_with_open_groups_should_add_new_server_to_server_list_and_groups
    @session.open_groups.concat([:first, :second])
    server = @session.use('host')
    assert_equal [server], @session.groups[:first].sort
    assert_equal [server], @session.groups[:second].sort
  end

  def test_use_with_default_gateway_should_set_gateway_on_server
    Net::SSH::Gateway.expects(:new).with('host', 'user', {}).returns(:gateway)
    @session.via('host', 'user')
    server = @session.use('host2')
    assert_equal :gateway, server.gateway
  end

  def test_use_with_duplicate_server_will_not_add_server_twice
    s1, s2 = @session.use('host', 'host')
    assert_equal 1, @session.servers.length
    assert_equal s1.object_id, s2.object_id
  end

  def test_with_should_yield_new_subsession_with_servers_for_criteria
    yielded = nil
    @session.expects(:servers_for).with(:app, :web).returns([:servers])
    result = @session.with(:app, :web) do |s|
      yielded = s
    end
    assert_equal result, yielded
    assert_equal [:servers], yielded.servers
  end

  def test_servers_for_with_unknown_constraint_should_raise_error
    assert_raises(ArgumentError) do
      @session.servers_for(:app => { :all => :foo })
    end
  end

  def test_with_with_constraints_should_build_subsession_with_matching_servers
    conditions = { :app => { :only => { :primary => true }, :except => { :backup => true } } }
    @session.expects(:servers_for).with(conditions).returns([:servers])
    assert_equal [:servers], @session.with(conditions).servers
  end

  def test_on_should_return_subsession_containing_only_the_given_servers
    s1, s2 = @session.use('h1', 'h2')
    subsession = @session.on(s1, s2)
    assert_equal [s1, s2], subsession.servers
  end

  def test_on_should_yield_subsession_if_block_is_given
    s1 = @session.use('h1')
    yielded = nil
    result = @session.on(s1) do |s|
      yielded = s
      assert_equal [s1], s.servers
    end
    assert_equal result, yielded
  end

  def test_servers_for_should_return_all_servers_if_no_arguments
    srv1, srv2, srv3 = @session.use('h1', 'h2', 'h3')
    assert_equal [srv1, srv2, srv3], @session.servers_for.sort
  end

  def test_servers_for_should_return_servers_only_for_given_group
    srv1, srv2, srv3 = @session.use('h1', 'h2', 'h3')
    @session.group :app => [srv1, srv2], :db => [srv3]
    assert_equal [srv1, srv2], @session.servers_for(:app).sort
  end

  def test_servers_for_should_not_return_duplicate_servers
    srv1, srv2, srv3 = @session.use('h1', 'h2', 'h3')
    @session.group :app => [srv1, srv2], :db => [srv2, srv3]
    assert_equal [srv1, srv2, srv3], @session.servers_for(:app, :db).sort
  end

  def test_servers_for_should_correctly_apply_only_and_except_constraints
    srv1, srv2, srv3 = @session.use('h1', :properties => {:a => 1}), @session.use('h2', :properties => {:a => 1, :b => 2}), @session.use('h3')
    @session.group :app => [srv1, srv2, srv3]
    assert_equal [srv1], @session.servers_for(:app => {:only => {:a => 1}, :except => {:b => 2}})
  end

  def test_close_should_close_server_sessions
    srv1, srv2 = @session.use('h1', 'h2')
    srv1.expects(:close_channels)
    srv2.expects(:close_channels)
    srv1.expects(:close)
    srv2.expects(:close)
    @session.close
  end

  def test_close_should_shutdown_default_gateway
    gateway = mock('gateway')
    gateway.expects(:shutdown!)
    Net::SSH::Gateway.expects(:new).returns(gateway)
    @session.via('host', 'user')
    @session.close
  end

  def test_loop_should_loop_until_process_is_false
    @session.expects(:process).with(5).times(4).returns(true,true,true,false).yields
    yielded = false
    @session.loop(5) { yielded = true }
    assert yielded
  end

  def test_preprocess_should_immediately_return_false_if_block_returns_false
    srv = @session.use('h1')
    srv.expects(:preprocess).never
    assert_equal false, @session.preprocess { false }
  end

  def test_preprocess_should_call_preprocess_on_component_servers
    srv = @session.use('h1')
    srv.expects(:preprocess)
    assert_equal :hello, @session.preprocess { :hello }
  end

  def test_preprocess_should_succeed_even_without_block
    srv = @session.use('h1')
    srv.expects(:preprocess)
    assert_equal true, @session.preprocess
  end

  def test_postprocess_should_call_postprocess_on_component_servers
    srv = @session.use('h1')
    srv.expects(:postprocess).with([:a], [:b])
    assert_equal true, @session.postprocess([:a], [:b])
  end

  def test_process_should_return_false_if_preprocess_returns_false
    assert_equal false, @session.process { false }
  end

  def test_process_should_call_select_on_combined_readers_and_writers_from_all_servers
    @session.expects(:postprocess).with([:b, :c], [:a, :c])
    srv1, srv2, srv3 = @session.use('h1', 'h2', 'h3')
    srv1.expects(:readers).returns([:a])
    srv1.expects(:writers).returns([:a])
    srv2.expects(:readers).returns([])
    srv2.expects(:writers).returns([])
    srv3.expects(:readers).returns([:b, :c])    
    srv3.expects(:writers).returns([:c])
    IO.expects(:select).with([:a, :b, :c], [:a, :c], nil, 5).returns([[:b, :c], [:a, :c]])
    @session.process(5)
  end
end