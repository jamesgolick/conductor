require 'net/ssh/multi/server'
require 'net/ssh/multi/dynamic_server'

module Net; module SSH; module Multi

  # Encapsulates a list of server objects, both dynamic (Net::SSH::Multi::DynamicServer)
  # and static (Net::SSH::Multi::Server). It attempts to make it transparent whether
  # a dynamic server set has been evaluated or not. Note that a ServerList is
  # NOT an Array, though it is Enumerable.
  class ServerList
    include Enumerable

    # Create a new ServerList that wraps the given server list. Duplicate entries
    # will be discarded.
    def initialize(list=[])
      @list = list.uniq
    end

    # Adds the given server to the list, and returns the argument. If an
    # identical server definition already exists in the collection, the
    # argument is _not_ added, and the existing server record is returned
    # instead.
    def add(server)
      index = @list.index(server)
      if index
        server = @list[index]
      else
        @list.push(server)
      end
      server
    end

    # Adds an array (or otherwise Enumerable list) of servers to this list, by
    # calling #add for each argument. Returns +self+.
    def concat(servers)
      servers.each { |server| add(server) }
      self
    end

    # Iterates over each distinct server record in the collection. This will
    # correctly iterate over server records instantiated by a DynamicServer
    # as well, but only if the dynamic server has been "evaluated" (see
    # Net::SSH::Multi::DynamicServer#evaluate!).
    def each
      @list.each do |server|
        case server
        when Server then yield server
        when DynamicServer then server.each { |item| yield item }
        else raise ArgumentError, "server list contains non-server: #{server.class}"
        end
      end
      self
    end

    # Works exactly as Enumerable#select, but returns the result as a new
    # ServerList instance.
    def select
      subset = @list.select { |i| yield i }
      ServerList.new(subset)
    end

    # Returns an array of all servers in the list, with dynamic server records
    # expanded. The result is an array of distinct server records (duplicates
    # are removed from the result).
    def flatten
      result = @list.inject([]) do |aggregator, server|
        case server
        when Server then aggregator.push(server)
        when DynamicServer then aggregator.concat(server)
        else raise ArgumentError, "server list contains non-server: #{server.class}"
        end
      end

      result.uniq
    end

    alias to_ary flatten
  end

end; end; end