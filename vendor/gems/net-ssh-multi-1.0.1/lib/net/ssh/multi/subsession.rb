require 'net/ssh/multi/session_actions'

module Net; module SSH; module Multi

  # A trivial class for representing a subset of servers. It is used
  # internally for restricting operations to a subset of all defined
  # servers.
  #
  #   subsession = session.with(:app)
  #   subsession.exec("hostname")
  class Subsession
    include SessionActions

    # The master session that spawned this subsession.
    attr_reader :master

    # The list of servers that this subsession can operate on.
    attr_reader :servers

    # Create a new subsession of the given +master+ session, that operates
    # on the given +server_list+.
    def initialize(master, server_list)
      @master  = master
      @servers = server_list.uniq
    end

    # Works as Array#slice, but returns a new subsession consisting of the
    # given slice of servers in this subsession. The new subsession will have
    # the same #master session as this subsession does.
    #
    #   s1 = subsession.slice(0)
    #   s2 = subsession.slice(3, -1)
    #   s3 = subsession.slice(1..4)
    def slice(*args)
      Subsession.new(master, Array(servers.slice(*args)))
    end

    # Returns a new subsession that consists of only the first server in the
    # server list of the current subsession. This is just convenience for
    # #slice(0):
    #
    #   s1 = subsession.first
    def first
      slice(0)
    end
  end

end; end; end