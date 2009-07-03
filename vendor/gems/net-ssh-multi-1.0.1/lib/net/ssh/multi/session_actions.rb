module Net; module SSH; module Multi

  # This module represents the actions that are available on session
  # collections. Any class that includes this module needs only provide a
  # +servers+ method that returns a list of Net::SSH::Multi::Server
  # instances, and the rest just works. See Net::SSH::Multi::Session and
  # Net::SSH::Multi::Subsession for consumers of this module.
  module SessionActions
    # Returns the session that is the "master". This defaults to +self+, but
    # classes that include this module may wish to change this if they are
    # subsessions that depend on a master session.
    def master
      self
    end

    # Connections are normally established lazily, as soon as they are needed.
    # This method forces all servers in the current container to have their
    # connections established immediately, blocking until the connections have
    # been made.
    def connect!
      sessions
      self
    end

    # Returns +true+ if any server in the current container has an open SSH
    # session that is currently processing any channels. If +include_invisible+
    # is +false+ (the default) then invisible channels (such as those created
    # by port forwarding) will not be counted; otherwise, they will be.
    def busy?(include_invisible=false)
      servers.any? { |server| server.busy?(include_invisible) }
    end

    # Returns an array of all SSH sessions, blocking until all sessions have
    # connected.
    def sessions
      threads = servers.map { |server| Thread.new { server.session(true) } if server.session.nil? }
      threads.each { |thread| thread.join if thread }
      servers.map { |server| server.session }.compact
    end

    # Sends a global request to the sessions for all contained servers
    # (see #sessions). This can be used to (e.g.) ping the remote servers to
    # prevent them from timing out.
    #
    #   session.send_global_request("keep-alive@openssh.com")
    #
    # If a block is given, it will be invoked when the server responds, with
    # two arguments: the Net::SSH connection that is responding, and a boolean
    # indicating whether the request succeeded or not.
    def send_global_request(type, *extra, &callback)
      sessions.each { |ssh| ssh.send_global_request(type, *extra, &callback) }
      self
    end

    # Asks all sessions for all contained servers (see #sessions) to open a
    # new channel. When each server responds, the +on_confirm+ block will be
    # invoked with a single argument, the channel object for that server. This
    # means that the block will be invoked one time for each session.
    #
    # All new channels will be collected and returned, aggregated into a new
    # Net::SSH::Multi::Channel instance.
    #
    # Note that the channels are "enhanced" slightly--they have two properties
    # set on them automatically, to make dealing with them in a multi-session
    # environment slightly easier:
    #
    # * :server => the Net::SSH::Multi::Server instance that spawned the channel
    # * :host => the host name of the server
    #
    # Having access to these things lets you more easily report which host
    # (e.g.) data was received from:
    #
    #   session.open_channel do |channel|
    #     channel.exec "command" do |ch, success|
    #       ch.on_data do |ch, data|
    #         puts "got data #{data} from #{ch[:host]}"
    #       end
    #     end
    #   end
    def open_channel(type="session", *extra, &on_confirm)
      channels = sessions.map do |ssh|
        ssh.open_channel(type, *extra) do |c|
          c[:server] = c.connection[:server]
          c[:host] = c.connection[:server].host
          on_confirm[c] if on_confirm
        end
      end
      Multi::Channel.new(master, channels)
    end

    # A convenience method for executing a command on multiple hosts and
    # either displaying or capturing the output. It opens a channel on all
    # active sessions (see #open_channel and #active_sessions), and then
    # executes a command on each channel (Net::SSH::Connection::Channel#exec).
    #
    # If a block is given, it will be invoked whenever data is received across
    # the channel, with three arguments: the channel object, a symbol identifying
    # which output stream the data was received on (+:stdout+ or +:stderr+)
    # and a string containing the data that was received:
    #
    #   session.exec("command") do |ch, stream, data|
    #     puts "[#{ch[:host]} : #{stream}] #{data}"
    #   end
    #
    # If no block is given, all output will be written to +$stdout+ or
    # +$stderr+, as appropriate.
    #
    # Note that #exec will also capture the exit status of the process in the
    # +:exit_status+ property of each channel. Since #exec returns all of the
    # channels in a Net::SSH::Multi::Channel object, you can check for the
    # exit status like this:
    #
    #   channel = session.exec("command") { ... }
    #   channel.wait
    #
    #   if channel.any? { |c| c[:exit_status] != 0 }
    #     puts "executing failed on at least one host!"
    #   end
    def exec(command, &block)
      open_channel do |channel|
        channel.exec(command) do |ch, success|
          raise "could not execute command: #{command.inspect} (#{ch[:host]})" unless success

          channel.on_data do |ch, data|
            if block
              block.call(ch, :stdout, data)
            else
              data.chomp.each_line do |line|
                $stdout.puts("[#{ch[:host]}] #{line}")
              end
            end
          end

          channel.on_extended_data do |ch, type, data|
            if block
              block.call(ch, :stderr, data)
            else
              data.chomp.each_line do |line|
                $stderr.puts("[#{ch[:host]}] #{line}")
              end
            end
          end

          channel.on_request("exit-status") do |ch, data|
            ch[:exit_status] = data.read_long
          end
        end
      end
    end

  end

end; end; end