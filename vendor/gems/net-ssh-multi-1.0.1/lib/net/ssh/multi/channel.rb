module Net; module SSH; module Multi
  # Net::SSH::Multi::Channel encapsulates a collection of Net::SSH::Connection::Channel
  # instances from multiple different connections. It allows for operations to
  # be performed on all contained channels, simultaneously, using an interface
  # mostly identical to Net::SSH::Connection::Channel itself.
  #
  # You typically obtain a Net::SSH::Multi::Channel instance via
  # Net::SSH::Multi::Session#open_channel or Net::SSH::Multi::Session#exec,
  # though there is nothing stopping you from instantiating one yourself with
  # a handful of Net::SSH::Connection::Channel objects (though they should be
  # associated with connections managed by a Net::SSH::Multi::Session object
  # for consistent behavior).
  #
  #   channel = session.open_channel do |ch|
  #     # ...
  #   end
  #
  #   channel.wait
  class Channel
    include Enumerable

    # The Net::SSH::Multi::Session instance that controls this channel collection.
    attr_reader :connection

    # The collection of Net::SSH::Connection::Channel instances that this multi-channel aggregates.
    attr_reader :channels

    # A Hash of custom properties that may be set and queried on this object.
    attr_reader :properties

    # Instantiate a new Net::SSH::Multi::Channel instance, controlled by the
    # given +connection+ (a Net::SSH::Multi::Session object) and wrapping the
    # given +channels+ (Net::SSH::Connection::Channel instances).
    #
    # You will typically never call this directly; rather, you'll get your
    # multi-channel references via Net::SSH::Multi::Session#open_channel and
    # friends.
    def initialize(connection, channels)
      @connection = connection
      @channels = channels
      @properties = {}
    end

    # Iterate over each component channel object, yielding each in order to the
    # associated block.
    def each
      @channels.each { |channel| yield channel }
    end

    # Retrieve the property (see #properties) with the given +key+.
    #
    #   host = channel[:host]
    def [](key)
      @properties[key]
    end

    # Set the property (see #properties) with the given +key+ to the given
    # +value+.
    #
    #   channel[:visited] = true
    def []=(key, value)
      @properties[key] = value
    end

    # Perform an +exec+ command on all component channels. The block, if given,
    # is passed to each component channel, so it will (potentially) be invoked
    # once for every channel in the collection. The block will receive two
    # parameters: the specific channel object being operated on, and a boolean
    # indicating whether the exec succeeded or not.
    #
    #   channel.exec "ls -l" do |ch, success|
    #     # ...
    #   end
    #
    # See the documentation in Net::SSH for Net::SSH::Connection::Channel#exec
    # for more information on how to work with the callback.
    def exec(command, &block)
      channels.each { |channel| channel.exec(command, &block) }
      self
    end

    # Perform a +request_pty+ command on all component channels. The block, if
    # given, is passed to each component channel, so it will (potentially) be
    # invoked once for every channel in the collection. The block will
    # receive two parameters: the specific channel object being operated on,
    # and a boolean indicating whether the pty request succeeded or not.
    #
    #   channel.request_pty do |ch, success|
    #     # ...
    #   end
    #
    # See the documentation in Net::SSH for
    # Net::SSH::Connection::Channel#request_pty for more information on how to
    # work with the callback.
    def request_pty(opts={}, &block)
      channels.each { |channel| channel.request_pty(opts, &block) }
      self
    end

    # Send the given +data+ to each component channel. It will be sent to the
    # remote process, typically being received on the process' +stdin+ stream.
    #
    #   channel.send_data "password\n"
    def send_data(data)
      channels.each { |channel| channel.send_data(data) }
      self
    end

    # Returns true as long as any of the component channels are active.
    #
    #   connection.loop { channel.active? }
    def active?
      channels.any? { |channel| channel.active? }
    end

    # Runs the connection's event loop until the channel is no longer active
    # (see #active?).
    #
    #   channel.exec "something"
    #   channel.wait
    def wait
      connection.loop { active? }
      self
    end

    # Closes all component channels.
    def close
      channels.each { |channel| channel.close }
      self
    end

    # Tells the remote process for each component channel not to expect any
    # further data from this end of the channel.
    def eof!
      channels.each { |channel| channel.eof! }
      self
    end

    # Registers a callback on all component channels, to be invoked when the
    # remote process emits data (usually on its +stdout+ stream). The block
    # will be invoked with two arguments: the specific channel object, and the
    # data that was received.
    #
    #   channel.on_data do |ch, data|
    #     puts "got data: #{data}"
    #   end
    def on_data(&block)
      channels.each { |channel| channel.on_data(&block) }
      self
    end

    # Registers a callback on all component channels, to be invoked when the
    # remote process emits "extended" data (typically on its +stderr+ stream).
    # The block will be invoked with three arguments: the specific channel
    # object, an integer describing the data type (usually a 1 for +stderr+)
    # and the data that was received.
    #
    #   channel.on_extended_data do |ch, type, data|
    #     puts "got extended data: #{data}"
    #   end
    def on_extended_data(&block)
      channels.each { |channel| channel.on_extended_data(&block) }
      self
    end

    # Registers a callback on all component channels, to be invoked during the
    # idle portion of the connection event loop. The callback will be invoked
    # with one argument: the specific channel object being processed.
    #
    #   channel.on_process do |ch|
    #     # ...
    #   end
    def on_process(&block)
      channels.each { |channel| channel.on_process(&block) }
      self
    end

    # Registers a callback on all component channels, to be invoked when the
    # remote server terminates the channel. The callback will be invoked
    # with one argument: the specific channel object being closed.
    #
    #   channel.on_close do |ch|
    #     # ...
    #   end
    def on_close(&block)
      channels.each { |channel| channel.on_close(&block) }
      self
    end

    # Registers a callback on all component channels, to be invoked when the
    # remote server has no further data to send. The callback will be invoked
    # with one argument: the specific channel object being marked EOF.
    #
    #   channel.on_eof do |ch|
    #     # ...
    #   end
    def on_eof(&block)
      channels.each { |channel| channel.on_eof(&block) }
      self
    end

    # Registers a callback on all component channels, to be invoked when the
    # remote server is unable to open the channel. The callback will be
    # invoked with three arguments: the channel object that couldn't be
    # opened, a description of the error (as a string), and an integer code
    # representing the error.
    #
    #   channel.on_open_failed do |ch, description, code|
    #     # ...
    #   end
    def on_open_failed(&block)
      channels.each { |channel| channel.on_open_failed(&block) }
      self
    end

    # Registers a callback on all component channels, to be invoked when the
    # remote server sends a channel request of the given +type+. The callback
    # will be invoked with two arguments: the specific channel object receiving
    # the request, and a Net::SSH::Buffer instance containing the request-specific
    # data.
    #
    #   channel.on_request("exit-status") do |ch, data|
    #     puts "exited with #{data.read_long}"
    #   end
    def on_request(type, &block)
      channels.each { |channel| channel.on_request(type, &block) }
      self
    end
  end
end; end; end