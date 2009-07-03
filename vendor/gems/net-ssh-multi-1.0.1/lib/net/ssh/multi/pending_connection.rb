require 'net/ssh/multi/channel_proxy'

module Net; module SSH; module Multi

  # A PendingConnection instance mimics a Net::SSH::Connection::Session instance,
  # without actually being an open connection to a server. It is used by
  # Net::SSH::Multi::Session when a concurrent connection limit is in effect,
  # so that a server can hang on to a "connection" that isn't really a connection.
  #
  # Any requests against this connection (like #open_channel or #send_global_request)
  # are not actually sent, but are added to a list of recordings. When the real
  # session is opened and replaces this pending connection, all recorded actions
  # will be replayed against that session.
  #
  # You'll never need to initialize one of these directly, and (if all goes well!)
  # should never even notice that one of these is in use. Net::SSH::Multi::Session
  # will instantiate these as needed, and only when there is a concurrent
  # connection limit.
  class PendingConnection
    # Represents a #open_channel action.
    class ChannelOpenRecording #:nodoc:
      attr_reader :type, :extras, :channel

      def initialize(type, extras, channel)
        @type, @extras, @channel = type, extras, channel
      end

      def replay_on(session)
        real_channel = session.open_channel(type, *extras, &channel.on_confirm)
        channel.delegate_to(real_channel)
      end
    end

    # Represents a #send_global_request action.
    class SendGlobalRequestRecording #:nodoc:
      attr_reader :type, :extra, :callback

      def initialize(type, extra, callback)
        @type, @extra, @callback = type, extra, callback
      end

      def replay_on(session)
        session.send_global_request(type, *extra, &callback)
      end
    end

    # The Net::SSH::Multi::Server object that "owns" this pending connection.
    attr_reader :server

    # Instantiates a new pending connection for the given Net::SSH::Multi::Server
    # object.
    def initialize(server)
      @server = server
      @recordings = []
    end

    # Instructs the pending session to replay all of its recordings against the
    # given +session+, and to then replace itself with the given session.
    def replace_with(session)
      @recordings.each { |recording| recording.replay_on(session) }
      @server.replace_session(session)
    end

    # Records that a channel open request has been made, and returns a new
    # Net::SSH::Multi::ChannelProxy object to represent the (as yet unopened)
    # channel.
    def open_channel(type="session", *extras, &on_confirm)
      channel = ChannelProxy.new(&on_confirm)
      @recordings << ChannelOpenRecording.new(type, extras, channel)
      return channel
    end

    # Records that a global request has been made. The request is not actually
    # sent, and won't be until #replace_with is called.
    def send_global_request(type, *extra, &callback)
      @recordings << SendGlobalRequestRecording.new(type, extra, callback)
      self
    end

    # Always returns +true+, so that the pending connection looks active until
    # it can be truly opened and replaced with a real connection.
    def busy?(include_invisible=false)
      true
    end

    # Does nothing, except to make a pending connection quack like a real connection.
    def close
      self
    end

    # Returns an empty array, since a pending connection cannot have any real channels.
    def channels
      []
    end

    # Returns +true+, and does nothing else.
    def preprocess
      true
    end

    # Returns +true+, and does nothing else.
    def postprocess(readers, writers)
      true
    end

    # Returns an empty hash, since a pending connection has no real listeners.
    def listeners
      {}
    end
  end

end; end; end