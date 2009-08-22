require 'net/ssh'

class SshSession
  attr_reader :ssh, :host

  def initialize(host)
    @ssh  = Net::SSH::Multi.start
    @host = host
    ssh.use(host)
  end

  def run(command)
    log = ""

    channel = ssh.exec(command) do |channel, stream, data|
      log << "[#{channel[:host]} #{stream.to_s.upcase}]: #{data}\n"
    end
    ssh.loop

    CommandResult.new(host, log, channel[:exit_status])
  end
end

