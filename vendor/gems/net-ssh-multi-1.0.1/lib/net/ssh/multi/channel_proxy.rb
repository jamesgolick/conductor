module Net; module SSH; module Multi

  # The ChannelProxy is a delegate class that represents a channel that has
  # not yet been opened. It is only used when Net::SSH::Multi is running with
  # with a concurrent connections limit (see Net::SSH::Multi::Session#concurrent_connections).
  #
  # You'll never need to instantiate one of these directly, and will probably
  # (if all goes well!) never even notice when one of these is in use. Essentially,
  # it is spawned by a Net::SSH::Multi::PendingConnection when the pending
  # connection is asked to open a channel. Any actions performed on the
  # channel proxy will then be recorded, until a real channel is set as the
  # delegate (see #delegate_to). At that point, all recorded actions will be
  # replayed on the channel, and any subsequent actions will be immediately
  # delegated to the channel.
  class ChannelProxy
    # This is the "on confirm" callback that gets called when the real channel
    # is opened.
    attr_reader :on_confirm

    # Instantiates a new channel proxy with the given +on_confirm+ callback.
    def initialize(&on_confirm)
      @on_confirm = on_confirm
      @recordings = []
      @channel = nil
    end

    # Instructs the proxy to delegate all further actions to the given +channel+
    # (which must be an instance of Net::SSH::Connection::Channel). All recorded
    # actions are immediately replayed, in order, against the delegate channel.
    def delegate_to(channel)
      @channel = channel
      @recordings.each do |sym, args, block|
        @channel.__send__(sym, *args, &block)
      end
    end

    # If a channel delegate has been specified (see #delegate_to), the method
    # will be immediately sent to the delegate. Otherwise, the call is added
    # to the list of recorded method calls, to be played back when a delegate
    # is specified.
    def method_missing(sym, *args, &block)
      if @channel
        @channel.__send__(sym, *args, &block)
      else
        @recordings << [sym, args, block]
      end
    end
  end

end; end; end