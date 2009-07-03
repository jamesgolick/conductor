require 'thread'
require 'net/ssh/gateway'
require 'net/ssh/multi/server'
require 'net/ssh/multi/dynamic_server'
require 'net/ssh/multi/server_list'
require 'net/ssh/multi/channel'
require 'net/ssh/multi/pending_connection'
require 'net/ssh/multi/session_actions'
require 'net/ssh/multi/subsession'

module Net; module SSH; module Multi
  # Represents a collection of connections to various servers. It provides an
  # interface for organizing the connections (#group), as well as a way to
  # scope commands to a subset of all connections (#with). You can also provide
  # a default gateway connection that servers should use when connecting
  # (#via). It exposes an interface similar to Net::SSH::Connection::Session
  # for opening SSH channels and executing commands, allowing for these
  # operations to be done in parallel across multiple connections.
  #
  #   Net::SSH::Multi.start do |session|
  #     # access servers via a gateway
  #     session.via 'gateway', 'gateway-user'
  # 
  #     # define the servers we want to use
  #     session.use 'user1@host1'
  #     session.use 'user2@host2'
  # 
  #     # define servers in groups for more granular access
  #     session.group :app do
  #       session.use 'user@app1'
  #       session.use 'user@app2'
  #     end
  # 
  #     # execute commands on all servers
  #     session.exec "uptime"
  # 
  #     # execute commands on a subset of servers
  #     session.with(:app).exec "hostname"
  # 
  #     # run the aggregated event loop
  #     session.loop
  #   end
  #
  # Note that connections are established lazily, as soon as they are needed.
  # You can force the connections to be opened immediately, though, using the
  # #connect! method.
  #
  # == Concurrent Connection Limiting
  #
  # Sometimes you may be dealing with a large number of servers, and if you
  # try to have connections open to all of them simultaneously you'll run into
  # open file handle limitations and such. If this happens to you, you can set
  # the #concurrent_connections property of the session. Net::SSH::Multi will
  # then ensure that no more than this number of connections are ever open
  # simultaneously.
  #
  #   Net::SSH::Multi.start(:concurrent_connections => 5) do |session|
  #     # ...
  #   end
  #
  # Opening channels and executing commands will still work exactly as before,
  # but Net::SSH::Multi will transparently close finished connections and open
  # pending ones.
  #
  # == Controlling Connection Errors
  #
  # By default, Net::SSH::Multi will raise an exception if a connection error
  # occurs when connecting to a server. This will typically bubble up and abort
  # the entire connection process. Sometimes, however, you might wish to ignore
  # connection errors, for instance when starting a daemon on a large number of
  # boxes and you know that some of the boxes are going to be unavailable.
  #
  # To do this, simply set the #on_error property of the session to :ignore
  # (or to :warn, if you want a warning message when a connection attempt
  # fails):
  #
  #   Net::SSH::Multi.start(:on_error => :ignore) do |session|
  #     # ...
  #   end
  #
  # The default is :fail, which causes the exception to bubble up. Additionally,
  # you can specify a Proc object as the value for #on_error, which will be
  # invoked with the server in question if the connection attempt fails. You
  # can force the connection attempt to retry by throwing the :go symbol, with
  # :retry as the payload, or force the exception to be reraised by throwing
  # :go with :raise as the payload:
  #
  #   handler = Proc.new do |server|
  #     server[:connection_attempts] ||= 0
  #     if server[:connection_attempts] < 3
  #       server[:connection_attempts] += 1
  #       throw :go, :retry
  #     else
  #       throw :go, :raise
  #     end
  #   end
  #
  #   Net::SSH::Multi.start(:on_error => handler) do |session|
  #     # ...
  #   end
  #
  # Any other thrown value (or no thrown value at all) will result in the
  # failure being ignored.
  #
  # == Lazily Evaluated Server Definitions
  #
  # Sometimes you might be dealing with an environment where you don't know the
  # names or addresses of the servers until runtime. You can certainly dynamically
  # build server names and pass them to #use, but if the operation to determine
  # the server names is expensive, you might want to defer it until the server
  # is actually needed (especially if the logic of your program is such that
  # you might not even need to connect to that server every time the program
  # runs).
  #
  # You can do this by passing a block to #use:
  #
  #   session.use do |opt|
  #     lookup_ip_address_of_remote_host
  #   end
  #
  # See #use for more information about this usage.
  class Session
    include SessionActions

    # The Net::SSH::Multi::ServerList managed by this session.
    attr_reader :server_list

    # The default Net::SSH::Gateway instance to use to connect to the servers.
    # If +nil+, no default gateway will be used.
    attr_reader :default_gateway

    # The hash of group definitions, mapping each group name to a corresponding
    # Net::SSH::Multi::ServerList.
    attr_reader :groups

    # The number of allowed concurrent connections. No more than this number
    # of sessions will be open at any given time.
    attr_accessor :concurrent_connections

    # How connection errors should be handled. This defaults to :fail, but
    # may be set to :ignore if connection errors should be ignored, or
    # :warn if connection errors should cause a warning.
    attr_accessor :on_error

    # The default user name to use when connecting to a server. If a user name
    # is not given for a particular server, this value will be used. It defaults
    # to ENV['USER'] || ENV['USERNAME'], or "unknown" if neither of those are
    # set.
    attr_accessor :default_user

    # The number of connections that are currently open.
    attr_reader :open_connections #:nodoc:

    # The list of "open" groups, which will receive subsequent server definitions.
    # See #use and #group.
    attr_reader :open_groups #:nodoc:

    # Creates a new Net::SSH::Multi::Session instance. Initially, it contains
    # no server definitions, no group definitions, and no default gateway.
    #
    # You can set the #concurrent_connections property in the options. Setting
    # it to +nil+ (the default) will cause Net::SSH::Multi to ignore any
    # concurrent connection limit and allow all defined sessions to be open
    # simultaneously. Setting it to an integer will cause Net::SSH::Multi to
    # allow no more than that number of concurrently open sessions, opening
    # subsequent sessions only when other sessions finish and close.
    #
    #   Net::SSH::Multi.start(:concurrent_connections => 10) do |session|
    #     session.use ...
    #   end
    def initialize(options={})
      @server_list = ServerList.new
      @groups = Hash.new { |h,k| h[k] = ServerList.new }
      @gateway = nil
      @open_groups = []
      @connect_threads = []
      @on_error = :fail
      @default_user = ENV['USER'] || ENV['USERNAME'] || "unknown"

      @open_connections = 0
      @pending_sessions = []
      @session_mutex = Mutex.new

      options.each { |opt, value| send("#{opt}=", value) }
    end

    # At its simplest, this associates a named group with a server definition.
    # It can be used in either of two ways:
    #
    # First, you can use it to associate a group (or array of groups) with a
    # server definition (or array of server definitions). The server definitions
    # must already exist in the #server_list array (typically by calling #use):
    #
    #   server1 = session.use('host1', 'user1')
    #   server2 = session.use('host2', 'user2')
    #   session.group :app => server1, :web => server2
    #   session.group :staging => [server1, server2]
    #   session.group %w(xen linux) => server2
    #   session.group %w(rackspace backup) => [server1, server2]
    #
    # Secondly, instead of a mapping of groups to servers, you can just
    # provide a list of group names, and then a block. Inside the block, any
    # calls to #use will automatically associate the new server definition with
    # those groups. You can nest #group calls, too, which will aggregate the
    # group definitions.
    #
    #   session.group :rackspace, :backup do
    #     session.use 'host1', 'user1'
    #     session.group :xen do
    #       session.use 'host2', 'user2'
    #     end
    #   end
    def group(*args)
      mapping = args.last.is_a?(Hash) ? args.pop : {}

      if mapping.any? && block_given?
        raise ArgumentError, "must provide group mapping OR block, not both"
      elsif block_given?
        begin
          saved_groups = open_groups.dup
          open_groups.concat(args.map { |a| a.to_sym }).uniq!
          yield self
        ensure
          open_groups.replace(saved_groups)
        end
      else
        mapping.each do |key, value|
          (open_groups + Array(key)).uniq.each do |grp|
            groups[grp.to_sym].concat(Array(value))
          end
        end
      end
    end

    # Sets up a default gateway to use when establishing connections to servers.
    # Note that any servers defined prior to this invocation will not use the
    # default gateway; it only affects servers defined subsequently.
    #
    #   session.via 'gateway.host', 'user'
    #
    # You may override the default gateway on a per-server basis by passing the
    # :via key to the #use method; see #use for details.
    def via(host, user, options={})
      @default_gateway = Net::SSH::Gateway.new(host, user, options)
      self
    end

    # Defines a new server definition, to be managed by this session. The
    # server is at the given +host+, and will be connected to as the given
    # +user+. The other options are passed as-is to the Net::SSH session
    # constructor.
    #
    # If a default gateway has been specified previously (with #via) it will
    # be passed to the new server definition. You can override this by passing
    # a different Net::SSH::Gateway instance (or +nil+) with the :via key in
    # the +options+.
    #
    #   session.use 'host'
    #   session.use 'user@host2', :via => nil
    #   session.use 'host3', :user => "user3", :via => Net::SSH::Gateway.new('gateway.host', 'user')
    #
    # If only a single host is given, the new server instance is returned. You
    # can give multiple hosts at a time, though, in which case an array of
    # server instances will be returned.
    #
    #   server1, server2 = session.use "host1", "host2"
    #
    # If given a block, this will save the block as a Net::SSH::Multi::DynamicServer
    # definition, to be evaluated lazily the first time the server is needed.
    # The block will recive any options hash given to #use, and should return
    # +nil+ (if no servers are to be added), a String or an array of Strings
    # (to be interpreted as a connection specification), or a Server or an
    # array of Servers.
    def use(*hosts, &block)
      options = hosts.last.is_a?(Hash) ? hosts.pop : {}
      options = { :via => default_gateway }.merge(options)

      results = hosts.map do |host|
        server_list.add(Server.new(self, host, options))
      end

      if block
        results << server_list.add(DynamicServer.new(self, options, block))
      end

      group [] => results
      results.length > 1 ? results : results.first
    end

    # Essentially an alias for #servers_for without any arguments. This is used
    # primarily to satistfy the expectations of the Net::SSH::Multi::SessionActions
    # module.
    def servers
      servers_for
    end

    # Returns the set of servers that match the given criteria. It can be used
    # in any (or all) of three ways.
    #
    # First, you can omit any arguments. In this case, the full list of servers
    # will be returned.
    #
    #   all = session.servers_for
    #
    # Second, you can simply specify a list of group names. All servers in all
    # named groups will be returned. If a server belongs to multiple matching
    # groups, then it will appear only once in the list (the resulting list
    # will contain only unique servers).
    #
    #   servers = session.servers_for(:app, :db)
    #
    # Last, you can specify a hash with group names as keys, and property
    # constraints as the values. These property constraints are either "only"
    # constraints (which restrict the set of servers to "only" those that match
    # the given properties) or "except" constraints (which restrict the set of
    # servers to those whose properties do _not_ match). Properties are described
    # when the server is defined (via the :properties key):
    #
    #   session.group :db do
    #     session.use 'dbmain', 'user', :properties => { :primary => true }
    #     session.use 'dbslave', 'user2'
    #     session.use 'dbslve2', 'user2'
    #   end
    #
    #   # return ONLY on the servers in the :db group which have the :primary
    #   # property set to true.
    #   primary = session.servers_for(:db => { :only => { :primary => true } })
    #
    # You can, naturally, combine these methods:
    #
    #   # all servers in :app and :web, and all servers in :db with the
    #   # :primary property set to true
    #   servers = session.servers_for(:app, :web, :db => { :only => { :primary => true } })
    def servers_for(*criteria)
      if criteria.empty?
        server_list.flatten
      else
        # normalize the criteria list, so that every entry is a key to a
        # criteria hash (possibly empty).
        criteria = criteria.inject({}) do |hash, entry|
          case entry
          when Hash then hash.merge(entry)
          else hash.merge(entry => {})
          end
        end

        list = criteria.inject([]) do |aggregator, (group, properties)|
          raise ArgumentError, "the value for any group must be a Hash, but got a #{properties.class} for #{group.inspect}" unless properties.is_a?(Hash)
          bad_keys = properties.keys - [:only, :except]
          raise ArgumentError, "unknown constraint(s) #{bad_keys.inspect} for #{group.inspect}" unless bad_keys.empty?

          servers = groups[group].select do |server|
            (properties[:only] || {}).all? { |prop, value| server[prop] == value } &&
            !(properties[:except] || {}).any? { |prop, value| server[prop] == value }
          end

          aggregator.concat(servers)
        end

        list.uniq
      end
    end

    # Returns a new Net::SSH::Multi::Subsession instance consisting of the
    # servers that meet the given criteria. If a block is given, the
    # subsession will be yielded to it. See #servers_for for a discussion of
    # how these criteria are interpreted.
    #
    #   session.with(:app).exec('hostname')
    #
    #   session.with(:app, :db => { :primary => true }) do |s|
    #     s.exec 'date'
    #     s.exec 'uptime'
    #   end
    def with(*groups)
      subsession = Subsession.new(self, servers_for(*groups))
      yield subsession if block_given?
      subsession
    end

    # Works as #with, but for specific servers rather than groups. It will
    # return a new subsession (Net::SSH::Multi::Subsession) consisting of
    # the given servers. (Note that it requires that the servers in question
    # have been created via calls to #use on this session object, or things
    # will not work quite right.) If a block is given, the new subsession
    # will also be yielded to the block.
    #
    #   srv1 = session.use('host1', 'user')
    #   srv2 = session.use('host2', 'user')
    #   # ...
    #   session.on(srv1, srv2).exec('hostname')
    def on(*servers)
      subsession = Subsession.new(self, servers)
      yield subsession if block_given?
      subsession
    end

    # Closes the multi-session by shutting down all open server sessions, and
    # the default gateway (if one was specified using #via). Note that other
    # gateway connections (e.g., those passed to #use directly) will _not_ be
    # closed by this method, and must be managed externally.
    def close
      server_list.each { |server| server.close_channels }
      loop(0) { busy?(true) }
      server_list.each { |server| server.close }
      default_gateway.shutdown! if default_gateway
    end

    alias :loop_forever :loop

    # Run the aggregated event loop for all open server sessions, until the given
    # block returns +false+. If no block is given, the loop will run for as
    # long as #busy? returns +true+ (in other words, for as long as there are
    # any (non-invisible) channels open).
    def loop(wait=nil, &block)
      running = block || Proc.new { |c| busy? }
      loop_forever { break unless process(wait, &running) }
    end

    # Run a single iteration of the aggregated event loop for all open server
    # sessions. The +wait+ parameter indicates how long to wait for an event
    # to appear on any of the different sessions; +nil+ (the default) means
    # "wait forever". If the block is given, then it will be used to determine
    # whether #process returns +true+ (the block did not return +false+), or
    # +false+ (the block returned +false+).
    def process(wait=nil, &block)
      realize_pending_connections!
      wait = @connect_threads.any? ? 0 : wait

      return false unless preprocess(&block)

      readers = server_list.map { |s| s.readers }.flatten
      writers = server_list.map { |s| s.writers }.flatten

      readers, writers, = IO.select(readers, writers, nil, wait)

      if readers
        return postprocess(readers, writers)
      else
        return true
      end
    end

    # Runs the preprocess stage on all servers. Returns false if the block
    # returns false, and true if there either is no block, or it returns true.
    # This is called as part of the #process method.
    def preprocess(&block) #:nodoc:
      return false if block && !block[self]
      server_list.each { |server| server.preprocess }
      block.nil? || block[self]
    end

    # Runs the postprocess stage on all servers. Always returns true. This is
    # called as part of the #process method.
    def postprocess(readers, writers) #:nodoc:
      server_list.each { |server| server.postprocess(readers, writers) }
      true
    end

    # Takes the #concurrent_connections property into account, and tries to
    # return a new session for the given server. If the concurrent connections
    # limit has been reached, then a Net::SSH::Multi::PendingConnection instance
    # will be returned instead, which will be realized into an actual session
    # as soon as a slot opens up.
    #
    # If +force+ is true, the concurrent_connections check is skipped and a real
    # connection is always returned.
    def next_session(server, force=false) #:nodoc:
      # don't retry a failed attempt
      return nil if server.failed?

      @session_mutex.synchronize do
        if !force && concurrent_connections && concurrent_connections <= open_connections
          connection = PendingConnection.new(server)
          @pending_sessions << connection
          return connection
        end

        @open_connections += 1
      end

      begin
        server.new_session

      # I don't understand why this should be necessary--StandardError is a
      # subclass of Exception, after all--but without explicitly rescuing
      # StandardError, things like Errno::* and SocketError don't get caught
      # here!
      rescue Exception, StandardError => e
        server.fail!
        @session_mutex.synchronize { @open_connections -= 1 }

        case on_error
        when :ignore then
          # do nothing
        when :warn then
          warn("error connecting to #{server}: #{e.class} (#{e.message})")
        when Proc then
          go = catch(:go) { on_error.call(server); nil }
          case go
          when nil, :ignore then # nothing
          when :retry then retry
          when :raise then raise
          else warn "unknown 'go' command: #{go.inspect}"
          end
        else
          raise
        end

        return nil
      end
    end

    # Tells the session that the given server has closed its connection. The
    # session indicates that a new connection slot is available, which may be
    # filled by the next pending connection on the next event loop iteration.
    def server_closed(server) #:nodoc:
      @session_mutex.synchronize do
        unless @pending_sessions.delete(server.session)
          @open_connections -= 1
        end
      end
    end

    # Invoked by the event loop. If there is a concurrent_connections limit in
    # effect, this will close any non-busy sessions and try to open as many
    # new sessions as it can. It does this in threads, so that existing processing
    # can continue.
    #
    # If there is no concurrent_connections limit in effect, then this method
    # does nothing.
    def realize_pending_connections! #:nodoc:
      return unless concurrent_connections

      server_list.each do |server|
        server.close if !server.busy?(true)
        server.update_session!
      end

      @connect_threads.delete_if { |t| !t.alive? }

      count = concurrent_connections ? (concurrent_connections - open_connections) : @pending_sessions.length
      count.times do
        session = @pending_sessions.pop or break
        @connect_threads << Thread.new do
          session.replace_with(next_session(session.server, true))
        end
      end
    end
  end
end; end; end
