require 'net/ssh'

module Net; module SSH; module Multi
  # Encapsulates the connection information for a single remote server, as well
  # as the Net::SSH session corresponding to that information. You'll rarely
  # need to instantiate one of these directly: instead, you should use
  # Net::SSH::Multi::Session#use.
  class Server
    include Comparable

    # The Net::SSH::Multi::Session instance that manages this server instance.
    attr_reader :master

    # The host name (or IP address) of the server to connect to.
    attr_reader :host

    # The user name to use when logging into the server.
    attr_reader :user

    # The Hash of additional options to pass to Net::SSH when connecting
    # (including things like :password, and so forth).
    attr_reader :options

    # The Net::SSH::Gateway instance to use to establish the connection. Will
    # be +nil+ if the connection should be established without a gateway.
    attr_reader :gateway

    # Creates a new Server instance with the given connection information. The
    # +master+ argument must be a reference to the Net::SSH::Multi::Session
    # instance that will manage this server reference. The +options+ hash must
    # conform to the options described for Net::SSH::start, with two additions:
    #
    # * :via => a Net::SSH::Gateway instance to use when establishing a
    #   connection to this server.
    # * :user => the name of the user to use when logging into this server.
    #
    # The +host+ argument may include the username and port number, in which
    # case those values take precedence over similar values given in the +options+:
    #
    #   server = Net::SSH::Multi::Server.new(session, 'user@host:1234')
    #   puts server.user #-> user
    #   puts server.port #-> 1234
    def initialize(master, host, options={})
      @master = master
      @options = options.dup

      @user, @host, port = host.match(/^(?:([^;,:=]+)@|)(.*?)(?::(\d+)|)$/)[1,3]

      user_opt, port_opt = @options.delete(:user), @options.delete(:port)

      @user = @user || user_opt || master.default_user
      port ||= port_opt

      @options[:port] = port.to_i if port

      @gateway = @options.delete(:via)
      @failed = false
    end

    # Returns the value of the server property with the given +key+. Server
    # properties are described via the +:properties+ key in the options hash
    # when defining the Server.
    def [](key)
      (options[:properties] || {})[key]
    end

    # Sets the given key/value pair in the +:properties+ key in the options
    # hash. If the options hash has no :properties key, it will be created.
    def []=(key, value)
      (options[:properties] ||= {})[key] = value
    end

    # Returns the port number to use for this connection.
    def port
      options[:port] || 22
    end

    # Gives server definitions a sort order, and allows comparison.
    def <=>(server)
      [host, port, user] <=> [server.host, server.port, server.user]
    end

    alias :eql? :==

    # Generates a +Fixnum+ hash value for this object. This function has the
    # property that +a.eql?(b)+ implies +a.hash == b.hash+. The
    # hash value is used by class +Hash+. Any hash value that exceeds the
    # capacity of a +Fixnum+ will be truncated before being used.
    def hash
      @hash ||= [host, user, port].hash
    end

    # Returns a human-readable representation of this server instance.
    def to_s
      @to_s ||= begin
        s = "#{user}@#{host}"
        s << ":#{options[:port]}" if options[:port]
        s
      end
    end

    # Returns a human-readable representation of this server instance.
    def inspect
      @inspect ||= "#<%s:0x%x %s>" % [self.class.name, object_id, to_s]
    end

    # Returns +true+ if this server has ever failed a connection attempt.
    def failed?
      @failed
    end

    # Indicates (by default) that this server has just failed a connection
    # attempt. If +flag+ is false, this can be used to reset the failed flag
    # so that a retry may be attempted.
    def fail!(flag=true)
      @failed = flag
    end

    # Returns the Net::SSH session object for this server. If +require_session+
    # is false and the session has not previously been created, this will
    # return +nil+. If +require_session+ is true, the session will be instantiated
    # if it has not already been instantiated, via the +gateway+ if one is
    # given, or directly (via Net::SSH::start) otherwise.
    #
    #   if server.session.nil?
    #     puts "connecting..."
    #     server.session(true)
    #   end
    #
    # Note that the sessions returned by this are "enhanced" slightly, to make
    # them easier to deal with in a multi-session environment: they have a
    # :server property automatically set on them, that refers to this object
    # (the Server instance that spawned them).
    #
    #   assert_equal server, server.session[:server]
    def session(require_session=false)
      return @session if @session || !require_session
      @session ||= master.next_session(self)
    end

    # Returns +true+ if the session has been opened, and the session is currently
    # busy (as defined by Net::SSH::Connection::Session#busy?).
    def busy?(include_invisible=false)
      session && session.busy?(include_invisible)
    end

    # Closes this server's session. If the session has not yet been opened,
    # this does nothing.
    def close
      session.close if session
    ensure
      master.server_closed(self) if session
      @session = nil
    end

    public # but not published, e.g., these are used internally only...

      # Indicate that the session currently in use by this server instance
      # should be replaced by the given +session+ argument. This is used when
      # a pending session has been "realized". Note that this does not
      # actually replace the session--see #update_session! for that.
      def replace_session(session) #:nodoc:
        @ready_session = session
      end

      # If a new session has been made ready (see #replace_session), this
      # will replace the current session with the "ready" session. This
      # method is called from the event loop to ensure that sessions are
      # swapped in at the appropriate point (instead of in the middle of an
      # event poll).
      def update_session! #:nodoc:
        if @ready_session
          @session, @ready_session = @ready_session, nil
        end
      end

      # Returns a new session object based on this server's connection
      # criteria. Note that this will not associate the session with the
      # server, and should not be called directly; it is called internally
      # from Net::SSH::Multi::Session when a new session is required.
      def new_session #:nodoc:
        session = if gateway
          gateway.ssh(host, user, options)
        else
          Net::SSH.start(host, user, options)
        end

        session[:server] = self
        session
      rescue Net::SSH::AuthenticationFailed => error
        raise Net::SSH::AuthenticationFailed.new("#{error.message}@#{host}")
      end

      # Closes all open channels on this server's session. If the session has
      # not yet been opened, this does nothing.
      def close_channels #:nodoc:
        session.channels.each { |id, channel| channel.close } if session
      end

      # Runs the session's preprocess action, if the session has been opened.
      def preprocess #:nodoc:
        session.preprocess if session
      end

      # Returns all registered readers on the session, or an empty array if the
      # session is not open.
      def readers #:nodoc:
        return [] unless session
        session.listeners.keys.reject { |io| io.closed? }
      end

      # Returns all registered and pending writers on the session, or an empty
      # array if the session is not open.
      def writers #:nodoc:
        readers.select do |io|
          io.respond_to?(:pending_write?) && io.pending_write?
        end
      end

      # Runs the post-process action on the session, if the session has been
      # opened. Only the +readers+ and +writers+ that actually belong to this
      # session will be postprocessed by this server.
      def postprocess(readers, writers) #:nodoc:
        return true unless session
        listeners = session.listeners.keys
        session.postprocess(listeners & readers, listeners & writers)
      end
  end
end; end; end