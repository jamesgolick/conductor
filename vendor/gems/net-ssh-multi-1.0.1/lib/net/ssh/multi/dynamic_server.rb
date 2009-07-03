require 'net/ssh/multi/server'

module Net; module SSH; module Multi

  # Represents a lazily evaluated collection of servers. This will usually be
  # created via Net::SSH::Multi::Session#use(&block), and is useful for creating
  # server definitions where the name or address of the servers are not known
  # until run-time.
  #
  #   session.use { lookup_ip_address_of_server }
  #
  # This prevents +lookup_ip_address_of_server+ from being invoked unless the
  # server is actually needed, at which point it is invoked and the result
  # cached.
  #
  # The callback should return either +nil+ (in which case no new servers are
  # instantiated), a String (representing a connection specification), an
  # array of Strings, or an array of Net::SSH::Multi::Server instances.
  class DynamicServer
    # The Net::SSH::Multi::Session instance that owns this dynamic server record.
    attr_reader :master

    # The Proc object to call to evaluate the server(s)
    attr_reader :callback

    # The hash of options that will be used to initialize the server records.
    attr_reader :options

    # Create a new DynamicServer record, owned by the given Net::SSH::Multi::Session
    # +master+, with the given hash of +options+, and using the given Proc +callback+
    # to lazily evaluate the actual server instances.
    def initialize(master, options, callback)
      @master, @options, @callback = master, options, callback
      @servers = nil
    end

    # Returns the value for the given +key+ in the :properties hash of the
    # +options+. If no :properties hash exists in +options+, this returns +nil+.
    def [](key)
      (options[:properties] ||= {})[key]
    end

    # Sets the given key/value pair in the +:properties+ key in the options
    # hash. If the options hash has no :properties key, it will be created.
    def []=(key, value)
      (options[:properties] ||= {})[key] = value
    end

    # Iterates over every instantiated server record in this dynamic server.
    # If the servers have not yet been instantiated, this does nothing (e.g.,
    # it does _not_ automatically invoke #evaluate!).
    def each
      (@servers || []).each { |server| yield server }
    end

    # Evaluates the callback and instantiates the servers, memoizing the result.
    # Subsequent calls to #evaluate! will simply return the cached list of
    # servers.
    def evaluate!
      @servers ||= Array(callback[options]).map do |server|
          case server
          when String then Net::SSH::Multi::Server.new(master, server, options)
          else server
          end
        end
    end

    alias to_ary evaluate!
  end

end; end; end