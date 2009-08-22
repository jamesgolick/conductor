require 'net/ssh'
require 'net/sftp'

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

  def upload(file)
    sftp.upload!(file, file)
  end

  protected
    def sftp
      @sftp ||= Net::SFTP.start(hostname, username)
    end

    def hostname
      host.split("@").last
    end

    def username
      host.split("@").first
    end
end

