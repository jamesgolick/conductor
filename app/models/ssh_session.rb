require 'net/ssh'
require 'net/sftp'

class SshSession
  class ResultProxy < Array
    def initialize(channels)
      channels.each do |c|
        push Result.new(c.properties)
      end
    end

    def successful?
      all? { |r| r.successful? }
    end

    def failed_hosts
      reject { |r| r.successful? }
    end
  end

  class Result
    attr_reader :host, :exit_code

    def initialize(properties)
      @host      = properties[:host]
      @exit_code = properties[:exit_code]
    end

    def successful?
      exit_code == 0
    end
  end

  # leaving this untested, because testing it was just a big
  # jumble of mocks that were going to be super brittle
  #
  class Upload < Thread
    attr_reader :sftp

    def initialize(session, path, data)
      super do
        @sftp = Net::SFTP::Session.new(session.session || session.session(true))
        sftp.connect!
        sftp.file.open(path, "w") { |f| f.puts data }
      end
    end
  end

  attr_reader :ssh, :hosts, :servers

  def initialize(*hosts)
    @ssh     = Net::SSH::Multi.start
    @hosts   = hosts
    @servers = {}
    init_session
  end

  def run(command)
    channel = ssh.exec(command) do |channel, stream, data|
      yield(channel[:host], stream.to_sym, data) if block_given?
    end

    ssh.loop

    ResultProxy.new(channel.channels)
  end

  def put(opts)
    path = opts.delete(:path)
    opts.map { |k, v| Upload.new(servers[k], path, v) }.each(&:join)
  end

  protected
    def init_session
      hosts.each do |h|
        servers[h] = ssh.use(h, :forward_agent => true)
      end
    end
end

